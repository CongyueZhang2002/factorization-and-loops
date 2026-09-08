"""Tiny embedded PTX proof used before/independently of nvcc."""

PTX = r"""
.version 8.0
.target sm_80
.address_size 64

.visible .entry ff31_bench(
    .param .u64 p_xs, .param .u64 p_ys, .param .u64 p_out,
    .param .u32 p_count, .param .u32 p_iterations,
    .param .u32 p_prime, .param .u32 p_nprime,
    .param .u32 p_c1, .param .u32 p_c2
)
{
    .reg .pred %p<4>;
    .reg .b32 %r<20>;
    .reg .b64 %rd<12>;
    ld.param.u64 %rd1, [p_xs];
    ld.param.u64 %rd2, [p_ys];
    ld.param.u64 %rd3, [p_out];
    ld.param.u32 %r10, [p_count];
    ld.param.u32 %r11, [p_iterations];
    ld.param.u32 %r12, [p_prime];
    ld.param.u32 %r13, [p_nprime];
    ld.param.u32 %r14, [p_c1];
    ld.param.u32 %r15, [p_c2];
    mov.u32 %r1, %ctaid.x;
    mov.u32 %r2, %ntid.x;
    mov.u32 %r3, %tid.x;
    mad.lo.s32 %r0, %r1, %r2, %r3;
    setp.ge.u32 %p0, %r0, %r10;
    @%p0 ret;
    mul.wide.u32 %rd4, %r0, 4;
    add.u64 %rd5, %rd1, %rd4;
    add.u64 %rd6, %rd2, %rd4;
    ld.global.u32 %r4, [%rd5];
    ld.global.u32 %r5, [%rd6];
    mov.u32 %r6, 0;
LOOP:
    setp.ge.u32 %p0, %r6, %r11;
    @%p0 bra DONE;
    // x = MontMul(x,y) + c1
    mul.wide.u32 %rd7, %r4, %r5;
    cvt.u32.u64 %r7, %rd7;
    mul.lo.u32 %r8, %r7, %r13;
    mul.wide.u32 %rd8, %r8, %r12;
    add.u64 %rd9, %rd7, %rd8;
    shr.u64 %rd9, %rd9, 32;
    cvt.u32.u64 %r4, %rd9;
    setp.ge.u32 %p1, %r4, %r12;
    @%p1 sub.u32 %r4, %r4, %r12;
    add.u32 %r4, %r4, %r14;
    setp.ge.u32 %p1, %r4, %r12;
    @%p1 sub.u32 %r4, %r4, %r12;
    // y = MontMul(y,y) + c2
    mul.wide.u32 %rd7, %r5, %r5;
    cvt.u32.u64 %r7, %rd7;
    mul.lo.u32 %r8, %r7, %r13;
    mul.wide.u32 %rd8, %r8, %r12;
    add.u64 %rd9, %rd7, %rd8;
    shr.u64 %rd9, %rd9, 32;
    cvt.u32.u64 %r5, %rd9;
    setp.ge.u32 %p1, %r5, %r12;
    @%p1 sub.u32 %r5, %r5, %r12;
    add.u32 %r5, %r5, %r15;
    setp.ge.u32 %p1, %r5, %r12;
    @%p1 sub.u32 %r5, %r5, %r12;
    add.u32 %r6, %r6, 1;
    bra LOOP;
DONE:
    add.u64 %rd5, %rd3, %rd4;
    st.global.u32 [%rd5], %r4;
    ret;
}
"""
