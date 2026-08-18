# 🚀 CI/CD Pipeline Challenge

Welcome to your first DevOps engineering challenge! By the end of this project, you will have built a fully automated pipeline that takes code from GitHub all the way to a live server — with zero manual steps
This is the kind of infrastructure that powers real production systems at companies like Shopify, Netflix, and Stripe.
,
-

## 🎯 The Mission

You have been given a simple Python web application. Your job is **not** to change the app — your job is to build the infrastructure around it so that every time a developer pushes code to `main`, the following happens automatically:

```
Developer pushes code
        ↓
 Tests run automatically
        ↓
 Docker image is built & stored
        ↓
 App is deployed to a live server
        ↓
 Team receives an email: Success or Failure
```

If anything goes wrong during deployment, the system should **automatically recover** without anyone having to intervene.

---

## 📁 What You've Been Given

```
repo/
├── app.py              # A Flask web app — do not modify
├── test_app.py         # Tests for the app — do not modify
├── requirements.txt    # Python dependencies
└── .gitignore
```

Run the app locally to understand what it does before you start building:

```bash
pip install -r requirements.txt
python app.py
# Visit http://localhost:5000
```

Run the tests to see what "passing" looks like:

```bash
pytest test_app.py -v
```

All 3 tests should pass. Your pipeline must make these same tests pass in an automated environment.

---

## 🧰 Tools You Will Use

You are expected to research and use the following tools. Links to documentation are provided — reading docs is a core engineering skill.

| Tool | Purpose | Docs |
|------|---------|------|
| **Docker** | Package the app into a portable container | [docs.docker.com](https://docs.docker.com) |
| **DockerHub** | Store and version your Docker images | [hub.docker.com](https://hub.docker.com) |
| **GitHub Actions** | Automate the pipeline on every push | [docs.github.com/actions](https://docs.github.com/en/actions) |
| **AWS EC2** | A Linux server to host the live app | [AWS EC2 Getting Started](https://docs.aws.amazon.com/ec2/index.html) |
| **Gmail App Passwords** | Send email notifications securely | [Google App Passwords](https://support.google.com/accounts/answer/185833) |

---

## 📋 Your Deliverables

You must create the following files from scratch:

### 1. `Dockerfile`
Containerize the Flask app. Your image must:
- Be based on an official Python image
- Install all dependencies from `requirements.txt`
- Expose port `5000`
- Start the app when the container runs

Test it locally before moving on:
```bash
docker build -t techflow-app .
docker run -p 5000:5000 techflow-app
# Visit http://localhost:5000 — does it work?
```

---

### 2. `.github/workflows/pipeline.yml`
This is the heart of the project. Your pipeline must have **three jobs** that run in sequence:

**Job 1 — Test**
- Triggers on every push to `main`
- Spins up a Python environment
- Installs dependencies
- Runs `pytest test_app.py -v`
- The next job must NOT run if tests fail

**Job 2 — Build & Push**
- Only runs if Job 1 passes
- Logs into DockerHub using secrets (see Secrets section below)
- Builds the Docker image
- Pushes it to DockerHub tagged as both `latest` and the commit SHA

**Job 3 — Deploy**
- Only runs if Job 2 passes
- SSHs into your EC2 server using a stored private key
- Pulls the latest image
- Stops the old container and starts the new one
- Sends a success or failure email notification

> 💡 **Hint:** Look into `appleboy/ssh-action` for SSH deployment and `dawidd6/action-send-mail` for email — these are community GitHub Actions that do the heavy lifting for you.

---

### 3. `scripts/health_check.sh`
A bash script that runs on the EC2 server after deployment to verify the app is alive.

It should:
- Make an HTTP request to the app's `/health` endpoint
- Retry up to 5 times if it fails (the container needs a moment to start)
- Exit with code `0` if the app is healthy
- Exit with code `1` if all retries fail

> 💡 **Hint:** Look into the `curl` command with the `-o` and `-w` flags to get just the HTTP status code.

---

### 4. `scripts/rollback.sh`
A bash script that runs on EC2 **only if the health check fails**.

It should:
- Stop and remove the broken container
- Pull the previous stable image from DockerHub (tagged `previous_stable`)
- Start that image instead
- Verify the rollback worked

---

### 5. `scripts/tag_stable.sh` *(Stretch Goal)*
A bash script that runs on EC2 **before** each new deployment.

It should:
- Find the currently running container's image
- Tag it as `previous_stable` on DockerHub

This is what makes rollback possible. Without it, there's nothing to roll back to.

---

## 🔐 GitHub Secrets

Your pipeline must never contain passwords or keys in plain text. Store all sensitive values in **GitHub Secrets** (`Settings → Secrets and variables → Actions`).

You will need to configure these secrets in your repo:

| Secret Name | What It Is |
|-------------|-----------|
| `DOCKERHUB_USERNAME` | Your DockerHub username |
| `DOCKERHUB_TOKEN` | A DockerHub access token (not your password) |
| `EC2_HOST` | The public IP address of your EC2 instance |
| `EC2_SSH_KEY` | The full contents of your `.pem` private key file |
| `EMAIL_USERNAME` | Your Gmail address |
| `EMAIL_APP_PASSWORD` | A Gmail App Password (not your Gmail password) |
| `NOTIFY_EMAIL` | The email address to receive notifications |

Reference them in your YAML like this: `${{ secrets.SECRET_NAME }}`

---

## ☁️ EC2 Setup Checklist

Before your pipeline can deploy, your EC2 server needs to be ready. Complete these steps manually once:

- [ ] Launch a `t2.micro` Ubuntu 24.04 instance (free tier)
- [ ] Create and download a `.pem` key pair
- [ ] Open inbound ports: **22** (SSH) and **80** (HTTP) in the security group
- [ ] SSH into the server and install Docker:
  ```bash
  sudo apt-get update && sudo apt-get install -y docker.io
  sudo systemctl enable docker && sudo systemctl start docker
  sudo usermod -aG docker ubuntu
  ```
- [ ] Upload your scripts to `/home/ubuntu/` and make them executable:
  ```bash
  chmod +x /home/ubuntu/*.sh
  ```

---

## ✅ How You Will Know It Works

1. Push a commit to `main`
2. Go to the **Actions** tab in your GitHub repo and watch all 3 jobs turn green ✅
3. Visit `http://YOUR_EC2_IP` in a browser — you should see the Hello World message
4. Check your email — you should have received a success notification
5. **Bonus test:** Deliberately break something (e.g. make `app.py` crash on startup), push it, and verify that the pipeline catches the failure and rolls back automatically

---

## 🏆 Stretch Goals

Completed everything above? Try these:

- **Tagging** — also tag your Docker image with `previous_stable` before each deploy so rollback always has a target (implement `tag_stable.sh`)
- **Pull Request checks** — modify the pipeline to also run tests on pull requests, not just pushes to `main`
- **Separate environments** — create a `staging` branch that deploys to a second EC2 instance before anything reaches `main`
- **Secrets scanning** — add a step that checks for accidentally committed secrets using `trufflesecurity/trufflehog`

---

## 🚫 Rules

- Do **not** modify `app.py` or `test_app.py`
- Do **not** hardcode credentials anywhere in your files — use GitHub Secrets
- Do **not** copy a working solution from the internet — the goal is that you understand every line you write

---

## 💬 Getting Stuck?

That's part of the process. Before asking for help, try:

1. Reading the error message carefully — GitHub Actions logs are very detailed
2. Googling the exact error
3. Checking the official docs linked in the Tools table above
4. Asking a teammate

Good luck — you've got this. 🛠️

<!-- TechFlow automated deployment verified -->
<!-- TechFlow production promotion deployment verified -->
