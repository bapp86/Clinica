# 🏥 Infraestructura Hospital SanaVI - Cloud Project

Este proyecto despliega una arquitectura híbrida en AWS utilizando **Terraform**, **Kubernetes (EKS)** y **Serverless (Lambda)**.

## 🏗️ Arquitectura Desplegada

La solución implementa una VPC con segregación de redes (Pública/Privada) para garantizar la seguridad de los datos de los pacientes.

```mermaid
graph TD
    %% --- Estilos ---
    classDef public fill:#e3f2fd,stroke:#1565c0,stroke-width:2px;
    classDef private fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef aws fill:#fff3e0,stroke:#ef6c00,stroke-width:2px;
    classDef user fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;

    %% --- Nodos ---
    user((👤 Usuario Final<br>Internet)):::user

    subgraph AWS ["☁️ AWS Cloud (Región us-east-1)"]
        direction TB
        
        subgraph Regional ["Servicios Gestionados"]
            EKS_CP["🧠 EKS Control Plane<br>(Master Nodes)"]:::aws
            APIGW["🚪 API Gateway<br>(Endpoint /pacientes)"]:::aws
        end

        subgraph VPC ["🔒 VPC (etnetxxxx)"]
            IGW[Internet Gateway]:::aws

            subgraph Public ["🟢 Subredes Públicas (DMZ)"]
                NLB["⚖️ Load Balancer<br>(Entrada Frontend)"]:::public
                NAT["🛡️ NAT Gateway<br>(Salida Segura)"]:::public
            end

            subgraph Private ["🔴 Subredes Privadas (Zona Segura)"]
                subgraph EKS_Nodes ["📦 EKS Worker Nodes (EC2)"]
                    POD1["nginx-pod-1"]:::private
                    POD2["nginx-pod-2"]:::private
                end
                
                LAMBDA["⚡ Función Lambda<br>(Backend Python)"]:::private
            end
        end
    end

    %% --- Flujo Frontend (Web) ---
    user ==>|1. Tráfico Web HTTP| NLB
    NLB -->|Balanceo| POD1
    NLB -->|Balanceo| POD2

    %% --- Flujo Backend (Datos) ---
    user ==>|2. API JSON HTTPS| APIGW
    APIGW -->|Invoca| LAMBDA

    %% --- Conectividad Saliente (Updates) ---
    POD1 -.->|Updates| NAT
    LAMBDA -.->|Salida| NAT
    NAT -.-> IGW
    IGW -.- user
```

## 🛠️ Tecnologías Utilizadas##
IaC: Terraform

Orquestación: Amazon EKS (Kubernetes)

Backend: AWS Lambda (Python) & API Gateway

Seguridad: RBAC, Network Policies (Calico), IAM Roles

## 👥 Autores
Bryan Painemilla

Juan Crovetto
