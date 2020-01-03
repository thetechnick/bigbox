### Fix CRI-O packaging error:

```bash
# cri-o-2:1.16.0-0.1.rc1.git6a4b481.module_f31+6837+7e34758d.x86_64
perl -p0e "s/\.module_f31/.alpha.0.31/g;s/\+6837/.6837/g;s/\+7e34758d/.7e34758d/g" -i /usr/bin/crio
```
