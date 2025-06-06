# Week 8: DevOps Essentials. Docker. CI/CD

## Application conteinerization 
### 1. Docker 
Docker is a tool for packaging applications and their dependencies into containers. Containers ensure your app runs the same way everywhere—on your laptop, a server, or in the cloud. For this project, we will containerize both the backend (FastAPI) and frontend (Streamlit) so they can be easily deployed and run.

Process of wrapping your application is quite standard: imagine you have an empty OS, where you need to setup your application. The approximate steps would be:
**Step 1.** Install main tools: programming language, tools (like nginx, terminal apps, etc..) 
**Step 2.** Install libraries
**Step 3.** Copy your project to the container
**Step 4.** Setup environment variables
**Step 5.** Run the application

### 2. Backend containerization
Step 1: Select base container with python.
```Dockerfile 
FROM python:3.12-slim
```

Step 2: Install libraries
```Dockerfile
COPY ./backend/requirements.txt /backend/
RUN pip install --no-cache-dir --upgrade -r /backend/requirements.txt
```

Step 3: Copy project
```Dockerfile
COPY ./backend /backend
COPY ./models/best /models
```

Step 4: Setup environment
```Dockerfile
EXPOSE 8000
```
Step with port exposing can be ommited, as we expose port in `docker-compose.yaml` file.
We will setup env variables in `docker-compose.yaml` file. 


Step 5: Run
```Dockerfile
CMD ["python3", "/backend/backend.py"]
```

### 3. Frontend containerization
#### 3.1 Docker-compose DNS server 
When using Docker Compose, each service (like backend and frontend) runs in its own container and gets a unique network name, which is the same as the service name in the docker-compose.yml file. Docker Compose automatically sets up an internal DNS server so containers can find each other by these names. For example, the frontend can reach the backend at http://backend:8000 instead of using localhost or 0.0.0.0. This is why we need to update the backend URL in the frontend app - to use the backend’s service name, which Docker’s DNS will resolve to the correct container. 
#### 3.2 Update frontend.py
As now our backend hosted on `http://backend:8000/...`, but not the `http://0.0.0.0/...`, we need to make updated in frontend.py. 

```python
import os

BACKEND_URL = os.getenv("BACKEND_URL", "http://0.0.0.0:8000")

# rest is the same
```
Here we either read env variable (that would be created in the container), either set it as a default in case we run it manually. 

#### 3.3 Wrap up with docker
Step 1. 
```Dockerfile
FROM python:3.12-slim
```

Step 2.
```Dockerfile
COPY ./frontend/requirements.txt /frontend/requirements.txt
RUN pip install -r /frontend/requirements.txt 
```

Step 3.
```Dockerfile
COPY ./frontend /frontend
```

Step 4. 
Nothing here, we will setup everything in `docker-compose.yaml`

Step 5. 
```Dockerfile
CMD ["streamlit", "run", "/frontend/frontend.py"]
```


<br>
<hr>

Why we firstly copy `requirements.txt` & install libraries and only then copy whole project: 

Docker layer caching means Docker saves each step (layer) of your build. If nothing changes in a step, Docker reuses the saved layer instead of rebuilding it. This makes builds much faster, especially when only your code changes but dependencies stay the same.

### 4. Containers inspection
#### 4.1 How to list images
Image - is a prototype/template of a container
```bash
> docker images
REPOSITORY                          TAG          IMAGE ID       CREATED          SIZE
week8-frontend                      latest       f8718d305b45   4 minutes ago    623MB
week8-backend                       latest       644135399603   11 minutes ago   546MB
```
#### 4.2 How to list working containers
```bash
> docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS         PORTS                                         NAMES
6884007f5a2a   week8-frontend   "streamlit run /fron…"   4 minutes ago    Up 4 minutes   0.0.0.0:3000->8501/tcp, [::]:3000->8501/tcp   week8-frontend-1
cc9760729eeb   week8-backend    "python3 /backend/ba…"   12 minutes ago   Up 4 minutes   0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp   week8-backend-1
```

#### 4.3 How to list all containers
```bash
> docker ps -a
CONTAINER ID   IMAGE                            COMMAND                  CREATED          STATUS                      PORTS                                         NAMES
6884007f5a2a   week8-frontend                   "streamlit run /fron…"   5 minutes ago    Up 5 minutes                0.0.0.0:3000->8501/tcp, [::]:3000->8501/tcp   week8-frontend-1
cc9760729eeb   week8-backend                    "python3 /backend/ba…"   12 minutes ago   Up 5 minutes                0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp   week8-backend-1
b089314b5c40   ab7fb9b0b76b                     "/bin/sh -c 'pip ins…"   4 hours ago      Exited (1) 4 hours ago                                                    boring_morse
41137c7282cc   catthehacker/ubuntu:act-latest   "tail -f /dev/null"      47 hours ago     Exited (137) 46 hours ago                                                 act-Generate-ML-Report-generate-report-f9e8025ca5a28d1f8d1a19ca583508e41069d507333d42a754fe775ca19e83a7
4b9e078ad89a   catthehacker/ubuntu:act-latest   "tail -f /dev/null"      2 days ago       Exited (137) 46 hours ago                                                 act-Generate-CML-Report-generate-report-6e3144b790609694e989ec0e40ae5a95e33ec40c7e3059d2e65afb1ddda98418
```

#### 4.4 Delete image/container
```bash
> docker image rm image_id
> docker rm container_id
```

#### 4.5 Inspect container
It would be very similar to connect via ssh to some machine: 
```bash
> docker exec -it container_id bash
```

#### 4.6 Remove everything
Docker has its own disadvantages, one of them is amount of memory that it use. After some time using it, your pc would need to be cleared of unused containers, images, and volumes. For this you can use 
```bash
> docker system prune -a --volumes  
```
**It would remove everything related to docker**, in case you still need some containers/images, use commands from 4.4 section.

### 5. Docker compose 
Docker Compose is a tool that allows you to define and run multi-container Docker applications using a single YAML file (docker-compose.yaml). With Compose, you can describe all your services (like backend and frontend), their build instructions, environment variables, ports, and how they connect to each other. This makes it easy to start, stop, and manage all parts of your project together with a single command.
```yaml
services:
  backend: 
    build: 
      dockerfile: ./backend/Dockerfile
      context: .
    ports:
      - "8000:8000"
    environment:
      MODEL_DIR: /models
    networks:
      - net

  frontend: 
    build: 
      dockerfile: ./frontend/Dockerfile
      context: .
    ports:
      - "3000:8501"
    environment:
      BACKEND_URL: http://backend:8000
    networks:
      - net

networks:
  net:
    driver: bridge  
```

## Github CI
GitHub Actions is a tool that lets you automate building, testing, and deploying your code whenever you push changes to your repository. For this project, you can use a workflow file (for example, `cml_report.yml`) to automatically build your Docker images, run tests, and generate reports.

A typical CI workflow for this project will:

- Check out your code.
- Set up Python and install dependencies.
- Optionally, run tests or lint your code.
- Generate and upload reports (for example, using model artifacts).

**Example workflow file: `.github/workflows/cml_report.yml`**
```yaml
name: Generate ML Report

on:
  push:
    branches:
      - main
    paths:
      - 'models/**'
      - 'backend/**'
  workflow_dispatch:

jobs:
  run-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Dependencies
        run: python -m pip install -r requirements.txt

      - name: Run Backend and Test Predict Batch
        run: |
          cd backend
          python backend.py &
          BACKEND_PID=$!

          for i in {1..20}; do
            if curl -s http://localhost:8000/health | grep -q healthy; then
              echo "Backend is up!"
              break
            fi
            sleep 1
          done

          RESPONSE=$(curl -s -o response.json -w "%{http_code}" -X 'POST' \
            'http://localhost:8000/predict_batch' \
            -H 'accept: application/json' \
            -H 'Content-Type: multipart/form-data' \
            -F 'file=@../data/bank-sample.csv;type=text/csv')

          if [ "$RESPONSE" -eq 200 ]; then
            echo "predict_batch endpoint test passed."
          else
            echo "predict_batch endpoint test failed with status $RESPONSE"
            cat response.json
            kill $BACKEND_PID
            exit 1
          fi

          kill $BACKEND_PID

  generate-report:
    needs: run-tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4

      - name: Generate Report
        run: | 
          precision=$(jq '.precision' models/best/metadata.json)
          recall=$(jq '.recall' models/best/metadata.json)
          f1=$(jq '.f1' models/best/metadata.json)
          model_type=$(jq -r '.model_filename' models/best/metadata.json | sed -E 's/model_(.*)\.joblib/\1/')

          mkdir -p reports
          report_path=reports/best_model_report.md

          echo "# Best Model Report" > "$report_path"
          echo "" >> "$report_path"
          echo "## Model Info" >> "$report_path"
          echo "" >> "$report_path"
          echo "- **Model Type**: $model_type" >> "$report_path"

          echo "- **Parameters**:" >> "$report_path"
          jq -r '.params | to_entries[] | "  - \(.key): \(.value)"' models/best/metadata.json >> "$report_path"
          echo "" >> "$report_path"

          echo "## Metrics" >> "$report_path"
          echo "" >> "$report_path"
          echo "| Metric    | Value |" >> "$report_path"
          echo "|-----------|-------|" >> "$report_path"
          echo "| Precision | $precision |" >> "$report_path"
          echo "| Recall    | $recall |" >> "$report_path"
          echo "| F1 Score  | $f1 |" >> "$report_path"
          echo "" >> "$report_path"

          echo "## Images" >> "$report_path"
          echo "" >> "$report_path"
          for img in models/best/*.png; do
            rel_path=$(realpath --relative-to=reports "$img")
            echo "![Image]($rel_path)" >> "$report_path"
          done

      - name: Commit and push changes
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"

          git add reports/best_model_report.md
          git commit -m "ci: Best model report update" || echo "No changes to commit"
          git push https://x-access-token:${GITHUB_TOKEN}@github.com/${{ github.repository }}.git HEAD:${{ github.ref_name }}
```

### Potential problems

In the last step we do commit from actions to our repository. With that you may observe problems with permissions. To fix that check repository settings as written: 
![alt text](step_1.png)
![alt text](step_2.png)
