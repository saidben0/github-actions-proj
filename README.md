# github-actions-proj

### Use `Cloud9` to download python libraries
|------------------|
| requirements.txt |
|------------------|
| pymupdf==1.24.9  |
| joblib==1.4.2    |
|------------------|

#### Use `Cloud9` to create the `zip` file
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
