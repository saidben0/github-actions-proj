# land.llandman 

### Use `Cloud9` to download python libraries `zip` file
|------------------|
| requirements.txt |
|------------------|
| pymupdf==1.24.9  |
| joblib==1.4.2    |
|------------------|
```bash
# download the libraries
mkdir tmp && cd tmp
python3 -m pip install virtualenv
virtualenv .venv
source ./.venv/bin/activate
mkdir python
pip install pymupdf==1.24.9 joblib==1.4.2 -t ./python
# pip install -r requirements.txt -t ./python
# cp -r ../.venv/lib64/python3.9/site-packages/* .
# cd ..
zip -r python_libs.zip python
deactivate
aws lambda publish-layer-version --layer-name python_libs --zip-file fileb://python_libs.zip --compatible-runtimes python3.9
```


### Troubleshooting

#### Issue#1: `publishing Lambda Layer (python-libs) Version: operation error Lambda: PublishLayerVersion, https response error StatusCode: 400, RequestID: 01a11772-c7b6-4739-bbdd-b3b2126b30d0, InvalidParameterValueException: Uploaded file must be a non-empty zip`
   >>> FIX: edit `requirements.txt` then add any comment in it to trigger `null_resource.lambda_layer` to download python libraries; push the code after that to trigger the pipeline to run.

