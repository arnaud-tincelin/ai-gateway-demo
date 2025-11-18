# 🧠 APIM: AI Gateway Labs

Inspired from [🧪 AI Gateway labs](https://github.com/Azure-Samples/AI-Gateway/tree/main), rewritten in Terraform.

Usage:

1. configure your environment

    ```bash
    az login
    uv venv .venv
    source .venv/bin/activate
    uv sync
    ```

1. execute playbook [setup.ipynb](./setup.ipynb)
1. run labs in any order:
    - [load-balancing.ipynb](./load-balancing.ipynb)
    - [semantic-caching.ipynb](./semantic-caching.ipynb)
    - [token-metrics-emitting.ipynb](./token-metrics-emitting.ipynb)
    - [token-rate-limiting.ipynb](./token-rate-limiting.ipynb)
1. execute playbook [clean-up-resources.ipynb](./clean-up-resources.ipynb)
