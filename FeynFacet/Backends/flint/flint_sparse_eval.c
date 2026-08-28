#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <flint/flint.h>
#include <flint/nmod.h>
#include <flint/ulong_extras.h>

/*
 * Batched modular evaluation of split-sparse multiquadratic leaves.
 * All protocol words are unsigned 64-bit little-endian values.
 */

#define MQSE_SCALAR_COUNT 3U
#define MQSE_MAX_ROOT_COUNT 3U
#define MQSE_MAX_VARIABLE_COUNT (MQSE_SCALAR_COUNT + MQSE_MAX_ROOT_COUNT)

typedef struct
{
    mp_limb_t coefficient;
    uint64_t exponents[MQSE_MAX_VARIABLE_COUNT];
} mqse_term_t;

typedef struct
{
    uint64_t active_mask;
    size_t local_rank;
    size_t active_indices[MQSE_MAX_ROOT_COUNT];
    size_t numerator_offset;
    size_t numerator_count;
    size_t denominator_offset;
    size_t denominator_count;
} mqse_leaf_t;

typedef struct
{
    mp_limb_t prime;
    nmod_t modulus;
    size_t root_count;
    size_t variable_count;
    size_t grade_count;
    size_t leaf_count;
    size_t numerator_term_count;
    size_t denominator_term_count;
    mqse_leaf_t * leaves;
    mqse_term_t * numerator_terms;
    mqse_term_t * denominator_terms;
    size_t maximum_exponents[MQSE_MAX_VARIABLE_COUNT];
    size_t power_offsets[MQSE_MAX_VARIABLE_COUNT];
    size_t power_count;
    mp_limb_t inverse_two_power[MQSE_MAX_ROOT_COUNT + 1U];
} mqse_plan_t;

typedef struct
{
    size_t point_count;
    mp_limb_t * values;
} mqse_points_t;

typedef struct
{
    const mqse_plan_t * plan;
    const mqse_points_t * points;
    size_t first_job;
    size_t final_job;
    uint64_t * statuses;
    mp_limb_t * channels;
    int failed;
} mqse_worker_t;

static const unsigned char plan_magic[8] =
    {'M', 'Q', 'S', 'E', '1', 'P', '1', '\0'};
static const unsigned char points_magic[8] =
    {'M', 'Q', 'S', 'E', '1', 'Q', '1', '\0'};
static const unsigned char output_magic[8] =
    {'M', 'Q', 'S', 'E', '1', 'X', '1', '\0'};

static double wall_seconds(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
        return 0.0;
    return (double) ts.tv_sec + 1.0e-9 * (double) ts.tv_nsec;
}

static int checked_add_size(size_t a, size_t b, size_t * result)
{
    if (b > SIZE_MAX - a)
        return 0;
    *result = a + b;
    return 1;
}

static int checked_mul_size(size_t a, size_t b, size_t * result)
{
    if (a != 0U && b > SIZE_MAX / a)
        return 0;
    *result = a * b;
    return 1;
}

static int u64_to_size(uint64_t value, size_t * result)
{
    if (value > (uint64_t) SIZE_MAX)
        return 0;
    *result = (size_t) value;
    return 1;
}

static int read_u64_le(FILE * stream, uint64_t * value)
{
    unsigned char bytes[8];
    unsigned int index;
    uint64_t result = 0U;
    if (fread(bytes, 1U, sizeof(bytes), stream) != sizeof(bytes))
        return 0;
    for (index = 0U; index < 8U; ++index)
        result |= ((uint64_t) bytes[index]) << (8U * index);
    *value = result;
    return 1;
}

static int write_u64_le(FILE * stream, uint64_t value)
{
    unsigned char bytes[8];
    unsigned int index;
    for (index = 0U; index < 8U; ++index)
        bytes[index] = (unsigned char) ((value >> (8U * index)) & UINT64_C(255));
    return fwrite(bytes, 1U, sizeof(bytes), stream) == sizeof(bytes);
}

static unsigned int small_popcount(uint64_t value)
{
    unsigned int count = 0U;
    while (value != 0U) {
        count += (unsigned int) (value & UINT64_C(1));
        value >>= 1U;
    }
    return count;
}

static unsigned int small_parity(size_t value)
{
    unsigned int parity = 0U;
    while (value != 0U) {
        parity ^= (unsigned int) (value & 1U);
        value >>= 1U;
    }
    return parity;
}

static void clear_plan(mqse_plan_t * plan)
{
    free(plan->leaves);
    free(plan->numerator_terms);
    free(plan->denominator_terms);
    memset(plan, 0, sizeof(*plan));
}

static int read_term(FILE * stream, mqse_plan_t * plan,
    const mqse_leaf_t * leaf, mqse_term_t * term)
{
    uint64_t word;
    size_t local_variable, global_variable, exponent;
    if (!read_u64_le(stream, &word) || word >= (uint64_t) plan->prime)
        return 0;
    term->coefficient = (mp_limb_t) word;
    for (local_variable = 0U;
         local_variable < MQSE_SCALAR_COUNT + leaf->local_rank;
         ++local_variable) {
        if (!read_u64_le(stream, &word) || !u64_to_size(word, &exponent))
            return 0;
        term->exponents[local_variable] = word;
        global_variable = local_variable < MQSE_SCALAR_COUNT
            ? local_variable
            : MQSE_SCALAR_COUNT
                + leaf->active_indices[local_variable - MQSE_SCALAR_COUNT];
        if (exponent > plan->maximum_exponents[global_variable])
            plan->maximum_exponents[global_variable] = exponent;
    }
    return 1;
}

static int read_plan(const char * path, mqse_plan_t * plan)
{
    FILE * stream = NULL;
    unsigned char magic[8];
    uint64_t prime_word, root_word, leaf_word, num_word, den_word;
    uint64_t active_word, rank_word, leaf_num_word, leaf_den_word;
    size_t leaf_index, term_index, root_index, numerator_seen = 0U;
    size_t denominator_seen = 0U, next, variable_power_count;
    size_t power_count = 0U;
    mqse_leaf_t * leaf;

    memset(plan, 0, sizeof(*plan));
    stream = fopen(path, "rb");
    if (stream == NULL)
        return 0;
    if (fread(magic, 1U, sizeof(magic), stream) != sizeof(magic)
        || memcmp(magic, plan_magic, sizeof(magic)) != 0
        || !read_u64_le(stream, &prime_word)
        || !read_u64_le(stream, &root_word)
        || !read_u64_le(stream, &leaf_word)
        || !read_u64_le(stream, &num_word)
        || !read_u64_le(stream, &den_word)
        || sizeof(mp_limb_t) != sizeof(uint64_t)
        || prime_word < UINT64_C(5) || (prime_word & UINT64_C(1)) == 0U
        || !n_is_prime((mp_limb_t) prime_word)
        || root_word > MQSE_MAX_ROOT_COUNT
        || leaf_word == 0U
        || !u64_to_size(root_word, &plan->root_count)
        || !u64_to_size(leaf_word, &plan->leaf_count)
        || !u64_to_size(num_word, &plan->numerator_term_count)
        || !u64_to_size(den_word, &plan->denominator_term_count)) {
        fclose(stream);
        return 0;
    }
    plan->prime = (mp_limb_t) prime_word;
    nmod_init(&plan->modulus, plan->prime);
    plan->variable_count = MQSE_SCALAR_COUNT + plan->root_count;
    plan->grade_count = ((size_t) 1U) << plan->root_count;
    if (!checked_mul_size(plan->leaf_count, sizeof(*plan->leaves), &next)
        || !checked_mul_size(plan->numerator_term_count,
            sizeof(*plan->numerator_terms), &next)
        || !checked_mul_size(plan->denominator_term_count,
            sizeof(*plan->denominator_terms), &next)) {
        fclose(stream);
        return 0;
    }
    plan->leaves = (mqse_leaf_t *) calloc(plan->leaf_count,
        sizeof(*plan->leaves));
    plan->numerator_terms = plan->numerator_term_count == 0U ? NULL
        : (mqse_term_t *) calloc(plan->numerator_term_count,
            sizeof(*plan->numerator_terms));
    plan->denominator_terms = plan->denominator_term_count == 0U ? NULL
        : (mqse_term_t *) calloc(plan->denominator_term_count,
            sizeof(*plan->denominator_terms));
    if (plan->leaves == NULL
        || (plan->numerator_term_count != 0U
            && plan->numerator_terms == NULL)
        || (plan->denominator_term_count != 0U
            && plan->denominator_terms == NULL)) {
        fclose(stream);
        clear_plan(plan);
        return 0;
    }

    for (leaf_index = 0U; leaf_index < plan->leaf_count; ++leaf_index) {
        leaf = plan->leaves + leaf_index;
        if (!read_u64_le(stream, &active_word)
            || !read_u64_le(stream, &rank_word)
            || !read_u64_le(stream, &leaf_num_word)
            || !read_u64_le(stream, &leaf_den_word)
            || active_word >= (((uint64_t) 1U) << plan->root_count)
            || rank_word > root_word
            || small_popcount(active_word) != (unsigned int) rank_word
            || leaf_den_word == 0U
            || !u64_to_size(rank_word, &leaf->local_rank)
            || !u64_to_size(leaf_num_word, &leaf->numerator_count)
            || !u64_to_size(leaf_den_word, &leaf->denominator_count)
            || !checked_add_size(numerator_seen, leaf->numerator_count, &next)
            || next > plan->numerator_term_count) {
            fclose(stream);
            clear_plan(plan);
            return 0;
        }
        leaf->active_mask = active_word;
        leaf->numerator_offset = numerator_seen;
        numerator_seen = next;
        if (!checked_add_size(denominator_seen, leaf->denominator_count, &next)
            || next > plan->denominator_term_count) {
            fclose(stream);
            clear_plan(plan);
            return 0;
        }
        leaf->denominator_offset = denominator_seen;
        denominator_seen = next;
        term_index = 0U;
        for (root_index = 0U; root_index < plan->root_count; ++root_index)
            if ((active_word & (((uint64_t) 1U) << root_index)) != 0U)
                leaf->active_indices[term_index++] = root_index;
        for (term_index = 0U; term_index < leaf->numerator_count; ++term_index)
            if (!read_term(stream, plan, leaf,
                plan->numerator_terms + leaf->numerator_offset + term_index)) {
                fclose(stream);
                clear_plan(plan);
                return 0;
            }
        for (term_index = 0U; term_index < leaf->denominator_count; ++term_index)
            if (!read_term(stream, plan, leaf,
                plan->denominator_terms + leaf->denominator_offset + term_index)) {
                fclose(stream);
                clear_plan(plan);
                return 0;
            }
    }
    if (numerator_seen != plan->numerator_term_count
        || denominator_seen != plan->denominator_term_count
        || fgetc(stream) != EOF || ferror(stream)) {
        fclose(stream);
        clear_plan(plan);
        return 0;
    }
    if (fclose(stream) != 0) {
        clear_plan(plan);
        return 0;
    }
    for (root_index = 0U; root_index < plan->variable_count; ++root_index) {
        plan->power_offsets[root_index] = power_count;
        if (!checked_add_size(plan->maximum_exponents[root_index], 1U,
                &variable_power_count)
            || !checked_add_size(power_count, variable_power_count,
                &power_count)) {
            clear_plan(plan);
            return 0;
        }
    }
    if (!checked_mul_size(power_count, sizeof(mp_limb_t), &next)) {
        clear_plan(plan);
        return 0;
    }
    plan->power_count = power_count;
    for (root_index = 0U; root_index <= MQSE_MAX_ROOT_COUNT; ++root_index)
        plan->inverse_two_power[root_index] = (mp_limb_t) n_invmod(
            (mp_limb_t) (((uint64_t) 1U) << root_index), plan->prime);
    return 1;
}

static void clear_points(mqse_points_t * points)
{
    free(points->values);
    memset(points, 0, sizeof(*points));
}

static int read_points(const char * path, const mqse_plan_t * plan,
    mqse_points_t * points)
{
    FILE * stream = NULL;
    unsigned char magic[8];
    uint64_t prime_word, root_word, leaf_word, point_word, value;
    size_t value_count, point_index, variable_index, byte_count;

    memset(points, 0, sizeof(*points));
    stream = fopen(path, "rb");
    if (stream == NULL)
        return 0;
    if (fread(magic, 1U, sizeof(magic), stream) != sizeof(magic)
        || memcmp(magic, points_magic, sizeof(magic)) != 0
        || !read_u64_le(stream, &prime_word)
        || !read_u64_le(stream, &root_word)
        || !read_u64_le(stream, &leaf_word)
        || !read_u64_le(stream, &point_word)
        || prime_word != (uint64_t) plan->prime
        || root_word != (uint64_t) plan->root_count
        || leaf_word != (uint64_t) plan->leaf_count
        || point_word == 0U
        || !u64_to_size(point_word, &points->point_count)
        || !checked_mul_size(points->point_count, plan->variable_count,
            &value_count)
        || !checked_mul_size(value_count, sizeof(*points->values),
            &byte_count)) {
        fclose(stream);
        return 0;
    }
    points->values = (mp_limb_t *) malloc(byte_count);
    if (points->values == NULL) {
        fclose(stream);
        return 0;
    }
    for (point_index = 0U; point_index < points->point_count; ++point_index)
        for (variable_index = 0U; variable_index < plan->variable_count;
             ++variable_index) {
            if (!read_u64_le(stream, &value) || value >= prime_word
                || (variable_index >= MQSE_SCALAR_COUNT && value == 0U)) {
                fclose(stream);
                clear_points(points);
                return 0;
            }
            points->values[point_index * plan->variable_count + variable_index]
                = (mp_limb_t) value;
        }
    if (fgetc(stream) != EOF || ferror(stream) || fclose(stream) != 0) {
        clear_points(points);
        return 0;
    }
    return 1;
}

static mp_limb_t evaluate_polynomial(const mqse_plan_t * plan,
    const mqse_leaf_t * leaf, const mqse_term_t * terms, size_t term_count,
    size_t branch, const mp_limb_t * powers)
{
    size_t term_index, variable, global_variable, exponent;
    unsigned int negative;
    mp_limb_t monomial, sum = 0U;
    const mqse_term_t * term;

    for (term_index = 0U; term_index < term_count; ++term_index) {
        term = terms + term_index;
        monomial = term->coefficient;
        negative = 0U;
        for (variable = 0U;
             variable < MQSE_SCALAR_COUNT + leaf->local_rank; ++variable) {
            exponent = (size_t) term->exponents[variable];
            global_variable = variable < MQSE_SCALAR_COUNT
                ? variable
                : MQSE_SCALAR_COUNT
                    + leaf->active_indices[variable - MQSE_SCALAR_COUNT];
            monomial = nmod_mul(monomial,
                powers[plan->power_offsets[global_variable] + exponent],
                plan->modulus);
            if (variable >= MQSE_SCALAR_COUNT
                && (exponent & 1U) != 0U
                && (branch & (((size_t) 1U)
                    << (variable - MQSE_SCALAR_COUNT))) != 0U)
                negative ^= 1U;
        }
        if (negative != 0U)
            monomial = nmod_neg(monomial, plan->modulus);
        sum = nmod_add(sum, monomial, plan->modulus);
    }
    return sum;
}

static uint64_t evaluate_leaf(const mqse_plan_t * plan,
    const mqse_leaf_t * leaf, const mp_limb_t * point,
    const mp_limb_t * root_inverses, const mp_limb_t * powers,
    mp_limb_t * output)
{
    mp_limb_t branch_values[1U << MQSE_MAX_ROOT_COUNT];
    mp_limb_t numerator, denominator, denominator_inverse, sum, root_inverse;
    const mqse_term_t * numerator_terms = leaf->numerator_count == 0U
        ? NULL : plan->numerator_terms + leaf->numerator_offset;
    size_t branch_count = ((size_t) 1U) << leaf->local_rank;
    size_t branch, local_mask, bit, global_mask;

    (void) point;
    for (branch = 0U; branch < branch_count; ++branch) {
        numerator = evaluate_polynomial(plan, leaf, numerator_terms,
            leaf->numerator_count, branch, powers);
        denominator = evaluate_polynomial(plan, leaf,
            plan->denominator_terms + leaf->denominator_offset,
            leaf->denominator_count, branch, powers);
        if (denominator == 0U)
            return UINT64_C(1);
        denominator_inverse = (mp_limb_t) n_invmod(denominator, plan->prime);
        branch_values[branch] = nmod_mul(numerator, denominator_inverse,
            plan->modulus);
    }
    for (local_mask = 0U; local_mask < branch_count; ++local_mask) {
        sum = 0U;
        for (branch = 0U; branch < branch_count; ++branch)
            sum = small_parity(branch & local_mask) == 0U
                ? nmod_add(sum, branch_values[branch], plan->modulus)
                : nmod_sub(sum, branch_values[branch], plan->modulus);
        sum = nmod_mul(sum, plan->inverse_two_power[leaf->local_rank],
            plan->modulus);
        global_mask = 0U;
        root_inverse = 1U;
        for (bit = 0U; bit < leaf->local_rank; ++bit)
            if ((local_mask & (((size_t) 1U) << bit)) != 0U) {
                global_mask |= ((size_t) 1U) << leaf->active_indices[bit];
                root_inverse = nmod_mul(root_inverse,
                    root_inverses[leaf->active_indices[bit]], plan->modulus);
            }
        output[global_mask] = nmod_mul(sum, root_inverse, plan->modulus);
    }
    return UINT64_C(0);
}

static void fill_powers(const mqse_plan_t * plan, const mp_limb_t * point,
    mp_limb_t * powers)
{
    size_t variable, exponent, offset;
    for (variable = 0U; variable < plan->variable_count; ++variable) {
        offset = plan->power_offsets[variable];
        powers[offset] = 1U;
        for (exponent = 1U;
             exponent <= plan->maximum_exponents[variable]; ++exponent)
            powers[offset + exponent] = nmod_mul(powers[offset + exponent - 1U],
                point[variable], plan->modulus);
    }
}

static void * evaluate_jobs(void * argument)
{
    mqse_worker_t * worker = (mqse_worker_t *) argument;
    const mqse_plan_t * plan = worker->plan;
    mp_limb_t * powers = (mp_limb_t *) malloc(
        plan->power_count * sizeof(*powers));
    mp_limb_t root_inverses[MQSE_MAX_ROOT_COUNT];
    const mp_limb_t * point = NULL;
    size_t cached_point = SIZE_MAX, job, point_index, leaf_index, root_index;
    size_t channel_offset;

    if (powers == NULL) {
        worker->failed = 1;
        return NULL;
    }
    for (job = worker->first_job; job < worker->final_job; ++job) {
        point_index = job / plan->leaf_count;
        leaf_index = job % plan->leaf_count;
        if (point_index != cached_point) {
            point = worker->points->values
                + point_index * plan->variable_count;
            fill_powers(plan, point, powers);
            for (root_index = 0U; root_index < plan->root_count; ++root_index)
                root_inverses[root_index] = (mp_limb_t) n_invmod(
                    point[MQSE_SCALAR_COUNT + root_index], plan->prime);
            cached_point = point_index;
        }
        channel_offset = job * plan->grade_count;
        worker->statuses[job] = evaluate_leaf(plan, plan->leaves + leaf_index,
            point, root_inverses, powers, worker->channels + channel_offset);
    }
    free(powers);
    return NULL;
}

static int write_output(const char * path, const mqse_plan_t * plan,
    const mqse_points_t * points, const uint64_t * statuses,
    const mp_limb_t * channels, size_t job_count, size_t channel_count)
{
    FILE * stream = fopen(path, "wb");
    size_t index;
    int ok = stream != NULL;
    if (!ok)
        return 0;
    ok = fwrite(output_magic, 1U, sizeof(output_magic), stream)
            == sizeof(output_magic)
        && write_u64_le(stream, (uint64_t) plan->prime)
        && write_u64_le(stream, (uint64_t) plan->root_count)
        && write_u64_le(stream, (uint64_t) plan->leaf_count)
        && write_u64_le(stream, (uint64_t) points->point_count);
    for (index = 0U; ok && index < job_count; ++index)
        ok = write_u64_le(stream, statuses[index]);
    for (index = 0U; ok && index < channel_count; ++index)
        ok = write_u64_le(stream, (uint64_t) channels[index]);
    if (fclose(stream) != 0)
        ok = 0;
    return ok;
}

int main(int argc, char ** argv)
{
    mqse_plan_t plan;
    mqse_points_t points;
    mqse_worker_t * workers = NULL;
    pthread_t * thread_ids = NULL;
    uint64_t * statuses = NULL;
    mp_limb_t * channels = NULL;
    char * end = NULL;
    long requested_threads = 1L;
    size_t thread_count, thread_index, job_count, channel_count, byte_count;
    size_t jobs_per_thread, extra_jobs, first_job;
    size_t launched = 0U;
    int result = 1, worker_failure = 0;
    double total_start, plan_start, plan_seconds, points_start, points_seconds;
    double evaluation_start, evaluation_seconds, output_start, output_seconds;

    memset(&plan, 0, sizeof(plan));
    memset(&points, 0, sizeof(points));
    if (argc != 4 && argc != 5) {
        fprintf(stderr, "usage: %s PLAN.bin POINTS.bin OUTPUT.bin [THREADS]\n",
            argv[0]);
        return 2;
    }
    if (argc == 5) {
        errno = 0;
        requested_threads = strtol(argv[4], &end, 10);
        if (errno != 0 || end == argv[4] || *end != '\0'
            || requested_threads < 1L || requested_threads > 8L) {
            fprintf(stderr, "THREADS must be between 1 and 8.\n");
            return 2;
        }
    }
    total_start = wall_seconds();
    plan_start = wall_seconds();
    if (!read_plan(argv[1], &plan)) {
        fprintf(stderr, "invalid or unsafe MQSE plan\n");
        return 3;
    }
    plan_seconds = wall_seconds() - plan_start;
    points_start = wall_seconds();
    if (!read_points(argv[2], &plan, &points)) {
        fprintf(stderr, "invalid or unsafe MQSE points\n");
        clear_plan(&plan);
        return 4;
    }
    points_seconds = wall_seconds() - points_start;
    if (!checked_mul_size(points.point_count, plan.leaf_count, &job_count)
        || !checked_mul_size(job_count, plan.grade_count, &channel_count)
        || !checked_mul_size(job_count, sizeof(*statuses), &byte_count))
        goto cleanup;
    statuses = (uint64_t *) calloc(job_count, sizeof(*statuses));
    if (statuses == NULL
        || !checked_mul_size(channel_count, sizeof(*channels), &byte_count))
        goto cleanup;
    channels = (mp_limb_t *) calloc(channel_count, sizeof(*channels));
    if (channels == NULL)
        goto cleanup;
    thread_count = (size_t) requested_threads;
    if (thread_count > job_count)
        thread_count = job_count;
    workers = (mqse_worker_t *) calloc(thread_count, sizeof(*workers));
    thread_ids = (pthread_t *) calloc(thread_count, sizeof(*thread_ids));
    if (workers == NULL || thread_ids == NULL)
        goto cleanup;

    evaluation_start = wall_seconds();
    jobs_per_thread = job_count / thread_count;
    extra_jobs = job_count % thread_count;
    first_job = 0U;
    for (thread_index = 0U; thread_index < thread_count; ++thread_index) {
        workers[thread_index].plan = &plan;
        workers[thread_index].points = &points;
        workers[thread_index].first_job = first_job;
        workers[thread_index].final_job = first_job + jobs_per_thread
            + (thread_index < extra_jobs ? 1U : 0U);
        first_job = workers[thread_index].final_job;
        workers[thread_index].statuses = statuses;
        workers[thread_index].channels = channels;
        if (pthread_create(thread_ids + thread_index, NULL, evaluate_jobs,
            workers + thread_index) != 0)
            break;
        launched++;
    }
    if (launched != thread_count)
        goto join_cleanup;
    for (thread_index = 0U; thread_index < launched; ++thread_index) {
        if (pthread_join(thread_ids[thread_index], NULL) != 0)
            worker_failure = 1;
        if (workers[thread_index].failed != 0)
            worker_failure = 1;
    }
    launched = 0U;
    if (worker_failure != 0)
        goto cleanup;
    evaluation_seconds = wall_seconds() - evaluation_start;
    output_start = wall_seconds();
    if (!write_output(argv[3], &plan, &points, statuses, channels,
        job_count, channel_count)) {
        fprintf(stderr, "failed writing MQSE output\n");
        goto cleanup;
    }
    output_seconds = wall_seconds() - output_start;
    printf("{\"backend\":\"FLINT-nmod-sparse-eval\","
           "\"prime\":%" PRIu64 ",\"roots\":%zu,\"leaves\":%zu,"
           "\"points\":%zu,\"threads\":%zu,\"plan_seconds\":%.9f,"
           "\"points_seconds\":%.9f,\"evaluation_seconds\":%.9f,"
           "\"output_seconds\":%.9f,\"total_seconds\":%.9f}\n",
        (uint64_t) plan.prime, plan.root_count, plan.leaf_count,
        points.point_count, thread_count, plan_seconds, points_seconds,
        evaluation_seconds, output_seconds, wall_seconds() - total_start);
    result = 0;
    goto cleanup;

join_cleanup:
    while (launched > 0U) {
        launched--;
        (void) pthread_join(thread_ids[launched], NULL);
    }
cleanup:
    if (result != 0)
        fprintf(stderr, "MQSE evaluation failed\n");
    free(workers);
    free(thread_ids);
    free(statuses);
    free(channels);
    clear_points(&points);
    clear_plan(&plan);
    flint_cleanup();
    return result;
}
