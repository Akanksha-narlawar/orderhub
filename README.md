# OrderHub Production Deployment

## Overview

OrderHub is a small Flask-based order management API.

The project demonstrates an end-to-end DevOps delivery process:

Git → Jenkins → Docker → Registry → Production

## Application Endpoints

### GET /

Returns:


{
  "message": "OrderHub API"
}