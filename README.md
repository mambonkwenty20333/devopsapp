# DevOps with Hilltop

A comprehensive 3-tier DevOps resources platform built with modern web technologies, providing curated tools, tutorials, and best practices for DevOps professionals.

## 🚀 Architecture

This application follows a robust 3-tier architecture:

- **Presentation Tier**: React.js frontend with responsive design
- **Application Tier**: Node.js/Express.js backend with RESTful APIs
- **Data Tier**: PostgreSQL database with Drizzle ORM

## 🛠 Tech Stack

### Frontend
- React 18 with TypeScript
- Tailwind CSS for styling
- Shadcn/ui component library
- TanStack Query for data management
- Wouter for routing

### Backend
- Node.js with Express.js
- TypeScript for type safety
- Drizzle ORM for database operations
- Zod for schema validation

### Database
- PostgreSQL for reliable data persistence
- Database migrations with Drizzle Kit

### DevOps & Deployment
- Docker for containerization
- Kubernetes for orchestration
- Helm charts for package management
- CircleCI for CI/CD pipeline

## 📋 Prerequisites

- Node.js 20.x or higher
- PostgreSQL 13+ (or use Docker)
- Docker (for containerization)
- Kubernetes cluster (for deployment)
- Helm 3.x (for package management)

## 🚀 Quick Start

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd devops-hilltop
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Set up the database**
   ```bash
   # Push database schema
   npm run db:push
   
   # Optional: Seed with sample data
   npm run db:seed
   ```

5. **Start the development server**
   ```bash
   npm run dev
   ```

The application will be available at `http://localhost:5000`

### Environment Variables

Create a `.env` file with the following variables:

```env
# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/devops_hilltop
PGUSER=username
PGPASSWORD=password
PGHOST=localhost
PGPORT=5432
PGDATABASE=devops_hilltop

# Application Configuration
NODE_ENV=development
PORT=5000
```

## 🐳 Docker Deployment

### Build and Run with Docker

```bash
# Build the Docker image
docker build -t devops-hilltop:latest .

# Run the container
docker run -p 5000:5000 \
  -e DATABASE_URL=your_database_url \
  devops-hilltop:latest
```

### Using Docker Compose

```bash
# Start all services (app + PostgreSQL)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## ☸️ Kubernetes Deployment

### Manual Deployment

1. **Apply Kubernetes manifests**
   ```bash
   # Create namespace
   kubectl apply -f k8s/namespace.yaml
   
   # Apply configurations
   kubectl apply -f k8s/configmap.yaml
   kubectl apply -f k8s/secret.yaml
   
   # Deploy application
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   kubectl apply -f k8s/ingress.yaml
   kubectl apply -f k8s/hpa.yaml
   ```

2. **Verify deployment**
   ```bash
   kubectl get pods -n devops-hilltop
   kubectl get services -n devops-hilltop
   ```

### Helm Deployment

1. **Install with Helm**
   ```bash
   # Add and update helm repo (if using external charts)
   helm repo update
   
   # Install the application
   helm install devops-hilltop ./helm/devops-hilltop \
     --namespace devops-hilltop \
     --create-namespace \
     --set image.tag=latest \
     --set ingress.hosts[0].host=your-domain.com
   ```

2. **Upgrade deployment**
   ```bash
   helm upgrade devops-hilltop ./helm/devops-hilltop \
     --namespace devops-hilltop \
     --set image.tag=v1.1.0
   ```

3. **Uninstall**
   ```bash
   helm uninstall devops-hilltop --namespace devops-hilltop
   ```

## 🔄 CI/CD Pipeline

The project includes a comprehensive CircleCI pipeline with the following stages:

### Pipeline Stages

1. **Test**: Runs linting and unit tests
2. **Security Scan**: Vulnerability scanning with Trivy
3. **Build & Push**: Builds Docker image and pushes to registry
4. **Deploy Staging**: Automatic deployment to staging environment
5. **Deploy Production**: Manual approval required for production deployment

### Setup Instructions

1. **Configure CircleCI environment variables:**
   ```
   DOCKER_USERNAME=your_docker_username
   DOCKER_PASSWORD=your_docker_password
   KUBE_CONFIG_DATA=base64_encoded_kubeconfig
   POSTGRES_PASSWORD_STAGING=staging_db_password
   POSTGRES_PASSWORD_PROD=production_db_password
   ```

2. **Trigger deployment:**
   - Push to `develop` branch → deploys to staging
   - Push to `main` branch → requires approval for production

## 🏗 Project Structure

```
devops-hilltop/
├── client/                 # React frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── pages/          # Page components
│   │   ├── lib/            # Utilities and API clients
│   │   └── hooks/          # Custom React hooks
│   └── index.html
├── server/                 # Express backend
│   ├── index.ts           # Server entry point
│   ├── routes.ts          # API routes
│   ├── storage.ts         # Database operations
│   └── db.ts              # Database connection
├── shared/                 # Shared types and schemas
│   └── schema.ts          # Database schema definitions
├── k8s/                   # Kubernetes manifests
├── helm/                  # Helm charts
├── .circleci/            # CI/CD configuration
├── Dockerfile            # Container definition
└── README.md             # This file
```

## 🔧 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run db:push` - Push database schema changes
- `npm run db:studio` - Open Drizzle Studio (database GUI)
- `npm run lint` - Run ESLint
- `npm test` - Run tests

## 🌟 Features

### Core Features
- **Resource Management**: Create, read, update, and delete DevOps resources
- **Category Organization**: Organize resources by DevOps practice areas
- **Search & Filter**: Advanced search and filtering capabilities
- **Contact System**: Contact form for user feedback and suggestions
- **Admin Dashboard**: Full administrative interface

### Technical Features
- **Responsive Design**: Mobile-first, responsive interface
- **SEO Optimized**: Meta tags and Open Graph support
- **Type Safety**: Full TypeScript implementation
- **Database Migrations**: Schema versioning with Drizzle
- **Health Checks**: Application health monitoring
- **Security**: Input validation, SQL injection prevention
- **Performance**: Optimized queries and caching

## 📊 Monitoring & Observability

### Health Checks
- Application health endpoint: `/health`
- Database connectivity monitoring
- Kubernetes liveness and readiness probes

### Logging
- Structured logging with request tracking
- Error logging and monitoring
- Performance metrics collection

## 🔒 Security Features

- Input validation with Zod schemas
- SQL injection prevention with ORM
- Security headers and CORS configuration
- Container security best practices
- Non-root container execution
- Read-only root filesystem

## 🚀 Deployment to AWS EKS

### Prerequisites
- AWS CLI configured
- eksctl installed
- kubectl installed
- Helm 3.x installed

### EKS Cluster Setup

1. **Create EKS cluster**
   ```bash
   eksctl create cluster \
     --name devops-hilltop-cluster \
     --region us-west-2 \
     --nodegroup-name workers \
     --node-type m5.large \
     --nodes 3 \
     --nodes-min 2 \
     --nodes-max 5 \
     --managed
   ```

2. **Install ingress controller**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml
   ```

3. **Install cert-manager (for SSL)**
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

4. **Deploy application**
   ```bash
   helm install devops-hilltop ./helm/devops-hilltop \
     --namespace devops-hilltop \
     --create-namespace \
     --set ingress.enabled=true \
     --set ingress.hosts[0].host=devops-hilltop.yourdomain.com
   ```

## 📚 API Documentation

### Endpoints

#### Categories
- `GET /api/categories` - List all categories
- `GET /api/categories/:id` - Get category by ID
- `POST /api/categories` - Create new category
- `PUT /api/categories/:id` - Update category
- `DELETE /api/categories/:id` - Delete category

#### Resources
- `GET /api/resources` - List resources (with optional filtering)
- `GET /api/resources/featured` - Get featured resources
- `GET /api/resources/:id` - Get resource by ID
- `POST /api/resources` - Create new resource
- `PUT /api/resources/:id` - Update resource
- `DELETE /api/resources/:id` - Delete resource

#### Contact
- `POST /api/contact` - Submit contact form
- `GET /api/contacts` - List contact messages (admin only)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

For support and questions:
- Open an issue on GitHub
- Contact the DevOps team at devops@hilltop.com
- Check the documentation wiki

## 🔮 Roadmap

- [ ] User authentication and authorization
- [ ] Resource rating and commenting system
- [ ] Advanced search with Elasticsearch
- [ ] GraphQL API
- [ ] Mobile application
- [ ] Integration with external DevOps tools
- [ ] Analytics and reporting dashboard

---

**Built with ❤️ by the DevOps with Hilltop team**