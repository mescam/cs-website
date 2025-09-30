# AGENTS.md - CS Website Knowledge Base

## Project Overview
This is an academic website for **mgr inż. Jakub Woźniak** from the Institute of Computer Science at Poznan University of Technology. The website serves as a resource hub for students taking distributed systems courses.

**Website URL**: https://www.cs.put.poznan.pl/jwozniak/  
**Contact**: jakub.wozniak@cs.put.poznan.pl

## Technology Stack
- **Static Site Generator**: Hugo
- **Theme**: typo
- **Deployment**: GitHub Actions (hugo.yml workflow)
- **Content Format**: Markdown with Hugo front matter

## Course Structure

### 1. Zarządzanie Systemami Rozproszonymi (ZSR) - Winter Semester
**Distributed Systems Management** - Lecture (15h) + Labs (45h)

#### Lectures (Mondays, 16:50, Room L0.2.9):
1. Introduction to DevOps and distributed systems
2. Application containers (Docker)
3. Kubernetes: Orchestration and container management
4. Monitoring and log management in distributed systems
5. Infrastructure as Code (IaC) and automation with Terraform
6. High Availability and Disaster Recovery
7. Compliance using ISO 27001 example

#### Labs (Mondays, 18:15, Lab 1.6.16):
1. Ansible: Configuration automation
2. Docker: Application containerization
3. Kubernetes: Cluster creation and scaling
4. Kubernetes: LivenessProbe, StatefulSet, and Ingress
5. Monitoring with Prometheus and Grafana
6. GitOps with ArgoCD
7. Service Mesh with Istio
8. Terraform: Cloud infrastructure creation
9. Terraform: Modules, variables, and remote state
10. AKS and Terraform - summary

**Assessment**: Final exam on January 27th during lecture time

### 2. Projektowanie Systemów Rozproszonych (PSR) - Summer Semester
**Distributed Systems Design** - Lecture + Project

#### Lectures (15 sessions covering):
1. Introduction to Distributed Systems
2. Components and Architecture of Distributed Systems
3. Monolithic and microservice architectures
4. Load planning and management in distributed systems
5. Architectural Patterns in Distributed Systems
6. Monoliths, Microservices, and Modular Monoliths
7. Migration Strategies from Monolith to Microservices
8. Orchestration and Choreography
9. Databases in Distributed Systems
10. Security and Authorization
11. Design and Deployment Techniques and Tools
12. Introduction to Public Clouds and Service Models
13. Serverless, PaaS, and FaaS
14. Trends, Perspectives, and Summary

#### Project Requirements:
- **Team Size**: Up to 3 people
- **Architecture**: Microservices (minimum 3 nodes)
- **Communication**: Asynchronous communication in at least one place
- **Cloud Services**: Use of SaaS services from any cloud (e.g., Azure Cognitive Services)
- **Deployment**: Serverless or Kubernetes-based architecture
- **Frontend**: Minimal frontend (e.g., Streamlit)
- **Infrastructure**: Infrastructure as Code (e.g., Terraform, ARM)
- **CI/CD**: Implementation (e.g., GitHub Actions, Azure DevOps)
- **Documentation**: Architecture diagram (e.g., draw.io)
- **Topic**: Free choice
- **Deadline**: Last class of the semester

## File Structure
```
/Users/jakub/dev/cs-website/
├── .github/workflows/hugo.yml          # GitHub Actions deployment
├── labs/                               # Lab materials (LaTeX sources)
│   ├── resources/istio_architecture.png
│   ├── 0-ansible.tex through 9-final.tex
│   ├── 100-azure-func.tex, 101-azure-func.tex
│   └── flake.nix (Nix development environment)
├── lectures/                           # Lecture slides (PDFs)
│   ├── 0-intro.pdf through 5-ha.pdf
│   └── psr-2.pdf, psr-3.pdf, psr-4.pdf
├── lectures-src/                       # LaTeX source for lectures
└── website/                           # Hugo website
    ├── hugo.yaml                      # Main configuration
    ├── content/                       # Markdown content
    │   ├── psr-proj.md               # PSR project info
    │   ├── psr-wyklady.md            # PSR lectures
    │   ├── zsr-lab.md                # ZSR labs
    │   ├── zsr-wyklady.md            # ZSR lectures
    │   └── zsr-wyniki.md             # ZSR results
    └── themes/typo/                   # Hugo theme
```

## Development Environment
- **Nix Flakes**: Used for reproducible development environments
- **LaTeX**: Lab materials and some lectures are written in LaTeX
- **Hugo**: Static site generation for the website

## Key Features
- **Student Resources**: Comprehensive lab scripts and lecture materials
- **Grade Publication**: Results published with student ID anonymization
- **Multi-language Support**: Content in Polish (primary audience)
- **Responsive Design**: Uses typo theme for clean, academic presentation

## Common Tasks
- **Content Updates**: Edit markdown files in `website/content/`
- **Lab Material Updates**: Modify LaTeX files in `labs/` directory
- **Lecture Updates**: Update PDF files in `lectures/` directory
- **Deployment**: Automatic via GitHub Actions on push to main branch

## Contact and Consultation
- **Office Hours**: By appointment via email
- **LinkedIn**: https://www.linkedin.com/in/wozniakjakub
- **Medium**: https://medium.com/@jakubwozniak
- **GitHub**: https://github.com/mescam

## Important Notes
- Website serves Polish-speaking computer science students
- Focus on practical, hands-on learning with modern DevOps and cloud technologies
- Strong emphasis on industry-relevant tools (Docker, Kubernetes, Terraform, Azure)
- Assessment includes both theoretical knowledge and practical project work