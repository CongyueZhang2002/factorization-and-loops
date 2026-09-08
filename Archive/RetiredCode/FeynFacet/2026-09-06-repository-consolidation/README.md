# Repository consolidation, 2026-09-06

Retired source is stored in Retired with its original repository-relative path.
Before contains exact pre-edit copies of files changed during consolidation.
manifest.json records every moved or deleted file, its original size and
timestamp, destination when retained, and the reason.

No code here is loaded by the package, production drivers or active tests.
Generated old DE/canonicalization/transport output was removed after preserving
source, correspondence, mathematical references and active test inputs.
Historical correspondence and design records are in Archive/History rather
than mixed into active source directories.

The two actively tested prototype implementations moved to Tests/Support.
The old transport environment's installed versions are recorded in
retired-transport-requirements.txt; this is historical environment information,
not a dependency specification for the current solver.

See the current production guide and Design/RepositoryConsolidation_2026-09-06.md
from the repository root for current commands and verification.
