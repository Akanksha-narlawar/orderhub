
# OrderHub Production Deployment

## 1. Overview

OrderHub is a Flask-based Order Management API demonstrating an end-to-end DevOps production deployment workflow:

Git → Jenkins → Docker → Registry → Production

The project demonstrates CI/CD, immutable Docker artifacts, deployment validation, rollback, security, incident troubleshooting, and deployment traceability.

---

## 2. Application

### Technology Stack

- Python 3.12
- Flask
- Gunicorn
- Pytest
- Docker
- Jenkins
- Git/GitHub
- Docker Hub

### API Endpoints

| Endpoint | Purpose |
|---|---|
| `/` | Application information |
| `/health` | Application health |
| `/orders` | Order data |
| `/version` | Version, build number, and Git commit |

Example:

json
{
  "version": "1.0.1",
  "build": "11",
  "commit": "6afa9ee"
}