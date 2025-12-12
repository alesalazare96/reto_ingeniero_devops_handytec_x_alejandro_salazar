# Reto Ingeniero DevOps handytec – Kubernetes + Helm en Azure y Bash en AlmaLinux
# Creado por Alejandro Salazar

Repositorio del reto técnico DevOps: aprovisionamiento de un clúster de Kubernetes en una nube pública mediante IaC, despliegue de un contenedor con Helm y creación de un script en Bash para comprobar la salud de una VM AlmaLinux.

> Nota: inicialmente se intentó realizar el reto en AWS/EKS usando Terraform. Ese intento se documenta al final con sus respectivas lecciones aprendidas, pero la solución completa y funcional está hecha sobre Azure (AKS).

---

## Índice

- [Sobre el reto](#-sobre-el-reto)
- [Estructura del repositorio](#-estructura-del-repositorio)
- [Requisitos previos](#-requisitos-previos)
- [Parte 1 – IaC en Azure: AKS + Helm](#-parte-1--iac-en-azure-aks--helm)
  - [1.1. Infraestructura con Terraform (AKS)](#11-infraestructura-con-terraform-aks)
  - [1.2. Despliegue del contenedor `nginxdemos/hello` con Helm](#12-despliegue-del-contenedor-nginxdemoshello-con-helm)
  - [1.3. Validación del entorno](#13-validación-del-entorno)
- [Parte 2 – Script Bash en AlmaLinux](#-parte-2--script-bash-en-almalinux)
  - [2.1. Creación de la VM AlmaLinux en Azure](#21-creación-de-la-vm-almalinux-en-azure)
  - [2.2. Copia y ejecución de `check_vm_health.sh`](#22-copia-y-ejecución-de-check_vm_healthsh)
- [Parte 3 – Diagrama de arquitectura](#-parte-3--diagrama-de-arquitectura)
- [Intento inicial en AWS/EKS](#-intento-inicial-en-awseks)

---

## Sobre el reto

**Objetivo general**

Como parte de las actividades de DevOps, se debe aprovisionar y administrar herramientas de computación distribuida en nubes públicas. El reto plantea:

1. **IaC (mediante Azure)**  
   - Crear la infraestructura necesaria para un clúster de Kubernetes usando Terraform y Azure (AKS).  
   - Desplegar el contenedor `nginxdemos/hello` desde Docker Hub utilizando Helm.

2. **Script en Bash sobre AlmaLinux**  
   - Crear un script en Bash que verifique:
     - Servicios fallidos (`systemd`).
     - Uso de memoria RAM.
     - Espacio en disco por partición.

3. **Diagrama**
   - Entregar un diagrama sencillo (JPG/PNG) con la arquitectura aprovisionada.

4. **Documentación**  
   - Documentar el paso a paso de configuración y ejecución en este `README.md`, siguiendo el estilo de los ejemplos proporcionados.

---

## Estructura del repositorio

Estructura del repositorio (se incluyen de igual manera capturas de las ejecuciones de la parte 1 y 2):

```text
.
├── main.tf                 # IaC principal: provider azurerm, Resource Group y AKS
├── variables.tf            # Variables de entrada para Terraform
├── helm/
│   └── hello-nginx/
│       ├── Chart.yaml      # Metadatos del chart
│       ├── values.yaml     # Valores por defecto (imagen, puerto, etc.)
│       └── templates/
│           ├── deployment.yaml  # Deployment de Kubernetes
│           └── service.yaml     # Service tipo LoadBalancer
├── script_parte2/
│   └── check_vm_health.sh  # Script Bash de chequeo de salud en AlmaLinux
├── diagrama_parte3/
│   └── diagrama_arquitectura.png    # Diagrama básico de la solución (AKS + Helm + VM AlmaLinux)
└── README.md               # Este archivo
```

---

## Requisitos

### Entorno local de desarrollo

- **Sistema operativo**: Windows 11 con WSL2 (Ubuntu).
- **CLI de Azure**: `az` (Azure CLI).
- **Terraform**
- **kubectl**
- **Helm 3**
- Cuenta de **Azure** con permisos suficientes para:
  - Crear Resource Groups.
  - Crear AKS.
  - Crear VMs (para AlmaLinux).
- Clave SSH configurada para conectarse a la VM de AlmaLinux (`~/.ssh/id_ed25519`).

---

## Parte 1 – IaC en Azure: AKS + Helm

### 1.1. Infraestructura con Terraform (AKS)

**Archivos principales:**

- `main.tf`
  - Configura el provider `azurerm`.
  - Crea el Resource Group.
  - Crea un cluster AKS con:
    - 1 nodo (`node_count = 1`).
    - Tamaño de VM compatible con la suscripción y región. (`Standard_D2s`)
    - `sku_tier = "Free"` para uso de laboratorio.
- `variables.tf`
  - Define variables como:
    - `azure_location` (`eastus2`).
    - `resource_group_name` (`rg-devops-reto-aks`).
    - `aks_cluster_name` (`devops-reto-aks`).
    - `environment` (`dev`).

> Importante: el tamaño de la VM del node pool se tuvo que ajustar varias veces porque algunos tamaños baratos no estaban permitidos en la suscripción/región. Finalmente se utilizó un tamaño de la familia `Standard_D2s` compatible con la región elegida.

**Pasos para aplicar la IaC**

1. Inicializar Terraform (descarga del provider `azurerm`):

   ```bash
   terraform init
   ```

2. Revisar el plan de ejecución:

   ```bash
   terraform plan -out plan.tfplan
   ```

3. Aplicar los cambios (creación del Resource Group y AKS):

   ```bash
   terraform apply "plan.tfplan"
   ```

4. Resultado esperado:
   - Resource Group creado: `rg-devops-reto-aks`
   - Cluster AKS creado: `devops-reto-aks`
   - Outputs útiles:
     - `resource_group_name`
     - `aks_cluster_name`
     - comando `az aks get-credentials` para conectar `kubectl`.

---

### 1.2. Despliegue del contenedor `nginxdemos/hello` con Helm

Una vez creado el AKS, se procede a:

#### 1.2.1. Obtener credenciales del cluster

```bash
az aks get-credentials   --resource-group rg-devops-reto-aks   --name devops-reto-aks   --overwrite-existing
```

Verificar que el contexto actual de `kubectl` apunte al AKS:

```bash
kubectl config current-context
```

#### 1.2.2. Crear namespace para el reto

```bash
kubectl create namespace reto-hello
```

#### 1.2.3. Helm chart `hello-nginx`

En la carpeta `helm/hello-nginx/` se creó un chart sencillo que:

- Usa la imagen `nginxdemos/hello` de Docker Hub.
- Expone el contenedor por el puerto 80.
- Crea un **Service** de tipo `LoadBalancer` para obtener una IP pública y poder acceder vía navegador (`20.12.121.49`).

Estructura del chart (simplificada):

```text
helm/
└── hello-nginx/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        └── service.yaml
```

> Los manifiestos YAML definen un `Deployment` con 1 réplica y un `Service` tipo LoadBalancer.

#### 1.2.4. Instalar el chart

Posicionado en la carpeta `helm/`:

```bash
cd helm
helm install hello-nginx ./hello-nginx --namespace reto-hello
```

Helm indicará que el release se desplegó correctamente y mostrará instrucciones para obtener la IP del `LoadBalancer`.

---

### 1.3. Validación del entorno

#### 1.3.1. Comprobar nodo de AKS

```bash
kubectl get nodes -o wide
```

Salida esperada (similar):

- 1 nodo con estado `Ready`.
- Sistema operativo Ubuntu.
- Runtime `containerd`.

#### 1.3.2. Comprobar pods y service

```bash
kubectl get pods -n reto-hello
kubectl get svc  -n reto-hello
```

Se espera:

- Un pod del tipo `hello-nginx-xxxxx` en estado `Running`.
- Un service `hello-nginx` con:
  - Tipo: `LoadBalancer`.
  - `EXTERNAL-IP`: una IP pública.
  - Puerto 80/TCP.

#### 1.3.3. Probar en el navegador

Con la IP externa del service:

```bash
http://20.12.121.49:80
```

Muestra la página HTML de prueba `nginxdemos/hello`

---

## Parte 2 – Script Bash en AlmaLinux

La segunda parte del reto pedía un script en Bash que:

- Liste servicios fallidos.
- Muestre el uso de memoria RAM.
- Muestre el uso de disco por partición.

### 2.1. Creación de la VM AlmaLinux en Azure

Desde el portal de Azure se creó:

- **Resource Group**: se puede reutilizar uno existente o crear otro.
- **VM**:
  - Imagen: **AlmaLinux 9** (x64)
  - Tamaño de máquina: un tamaño pequeño permitido por la suscripción/región (`Standard_D2`)
  - Usuario administrador: `azureuser`
  - Autenticación vía **SSH key**

Una vez creada, se obtuvo la IP pública de la VM (`20.246.71.54`).

Conexión desde WSL:

```bash
ssh azureuser@20.246.71.54
```

### 2.2. Copia y ejecución de `check_vm_health.sh`

El script `scripts/check_vm_health.sh` hace lo siguiente:

1. Muestra un encabezado identificando el script y el contexto del reto.
2. Lista los servicios fallidos de `systemd`:

   - Usa `systemctl --failed`.
   - Si no hay servicios fallidos, lo indica explícitamente.

3. Muestra el uso de memoria RAM:

   - Usa `free -h` para mostrar memoria total, usada y libre en formato legible.

4. Muestra el espacio en disco por partición (excluyendo `tmpfs` y `devtmpfs`):

   - Usa `df -h` con un filtro para enfocarse en particiones reales (por ejemplo `/`, `/boot`, etc.).

5. Imprime un mensaje final indicando que el chequeo fue exitoso.

#### 2.2.1. Copiar el script a la VM

Desde WSL:

```bash
scp ./scripts/check_vm_health.sh azureuser@20.246.71.54:~
```

#### 2.2.2. Dar permisos de ejecución y correrlo

Dentro de la VM:

```bash
ssh azureuser@20.246.71.54

chmod +x check_vm_health.sh
./check_vm_health.sh
```

Salida esperada:

- Sección de servicios fallidos: lista vacía o servicios en estado `failed`.
- Sección de RAM: tabla generada por `free -h`.
- Sección de disco: tabla de `df -h` con las particiones principales y porcentaje de uso.
- Mensaje final indicando que el chequeo de salud ha sido exitoso.

---

## Parte 3 – Diagrama de arquitectura

El repositorio debe incluir un archivo de diagrama en `diagram/architecture.png`.

El diagrama muestra, de forma sencilla:

- **Usuario/Desarrollador** en su máquina local (Windows 11 + WSL).
- **Terraform** actuando sobre **Azure**:
  - Creación de **Resource Group**.
  - Creación de **AKS** con un node pool.
- Dentro de AKS:
  - Namespace `reto-hello`.
  - Deployment de `nginxdemos/hello`.
  - Service tipo LoadBalancer exponiendo el pod hacia Internet.
- **VM AlmaLinux**:
  - Ubicada en el mismo o en otro Resource Group.
  - Acceso SSH desde el entorno local.
  - Ejecución del script `check_vm_health.sh`.

> El diagrama sirve para visualizar los componentes principales.

---

## Intento inicial en AWS/EKS

Aunque el reto permitía IaC usando Azure o AWS, se intentó primero una solución en AWS con:

- **Terraform + módulo `terraform-aws-modules/eks`**.
- Cluster EKS con node groups gestionados.
- VPC por defecto y subnets filtradas por zonas de disponibilidad soportadas.

Sin embargo, durante la creación del node group de EKS se encontró el error:

- `NodeCreationFailure: Unhealthy nodes in the kubernetes cluster`
- Mensajes relacionados con AMIs optimizadas de **Amazon Linux 2** y cambios recientes en la publicación de dichas AMI.

Puntos clave del intento en AWS:

- A nivel de **EC2**, las instancias se veían “En ejecución” y con comprobaciones de estado superadas.
- A nivel de **EKS**, el node group quedaba en estado `CREATE_FAILED` por nodos no saludables.
- Se revisaron logs de `cloud-init` y mensajes de SSM sin encontrar una causa directa para el fallo en EKS, más allá de los cambios en las AMIs.
- Amazon EKS dejó de publicar AMIs AL2 optimizadas y recomendaba usar AL2023 o Bottlerocket, lo que complicó el despliegue rápido con el módulo EKS usado.

**Decisión**: documentar este intento como aprendizaje, tras tres intentos por levantar los group nodes (cada uno tras 37 minutos ya entraba en error) y mover el enfoque completamente a **Azure/AKS**, donde sí se consiguió completar la IaC, el despliegue con Helm y la ejecución del script en AlmaLinux.

---
