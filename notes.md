# land.llandman 

## Publish New Lambda Layer Version
You need to update the content of `lambda-layer/requirements.txt`, which will trigger:
   1- `lambda-layer.yml` pipeline to call the re-usable workflow `publish-layer.yml`
   2- Once `publish-layer.yml` pipeline execution is `completed`, it will trigger both `realtime` and `batch` data-pipeline workflows to update the layer version of their lambda functions

*** Please note that in order for `realtime` and `batch` data-pipeline workflow to be triggered, the `lambda-layer.yml` pipeline file must referenced from the `default` git repo branch.

