# Lab 4

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 4 in this folder.

### CI timings

| Measurement | Baseline | Cache miss | Cache hit | Worth it? |
|---|---:|---:|---:|---|
| Pip install step | Not separately measured | Not separately measured | Not separately measured | Need step timings |
| Docker build job | 26 s | 31 s | 30 s | Not yet; no clear improvement |
| Whole workflow | 59 s | 61 s | 59 s | No clear improvement |

**Pip cache:** The pip cache is intended to reuse downloaded Python packages and reduce installation time. I need the individual installation-step timings and cache logs to confirm whether it helped.

**Docker layer cache:** The Docker layer cache is intended to reuse unchanged image layers. The build job took approximately 31 seconds on the first cached run and 30 seconds on the next run, compared with 26 seconds at baseline. Based on these measurements, there is no clear improvement in build-job time.

