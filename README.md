# Appical Plan

## Description
This repository describes the complete setup of the ruby monolith application we want to deploy on AWS(preferabally on EKS, but can be extended to any container orchestratotion tool). The topics we want to cover are mentioned below as separate headings, and then the plan for each is explained within them in form of diagrams, screenshots and bullet points. There are some assumptions made and some decisions taken which would also be mentioned at the end of the README. 

## Available Infromation:

```
Database: PostgresSQL
Backend: Ruby on Rails Monolith
Frontend: A few react apps
Mobile: 2 native apps
Integrations: Self hosted middelware
Runtime: Docker, running on VM's
CI/CD: GH Actions & Circle CI
Observability: basic metrics/logs, some stuff in Sentry & AppSignal, no
standardisation, no unified analytics tool.
```

### Descisions

**EKS**: I chose to go with EKS, as the applications are dockerized and Kubernetes is a great container orchestration tool. As the application is a monolith, we could also choose ECS, but with so many open source tools(Helm, Karpeneter, AWS load balancer controller, External Secrets, External DNS and many more) out there that make Kubernetes so feature rich, in the future in case of huge growth being on EKS will make scaling very easy.

**AWS**: I chose AWS as it is one of the leading cloud providers and has great services and a huge community.

**RDS PostgresSQL** - I chose a managed RDS instance as deploying a self managed databse and maintaing it is very difficult and a little outdated now, with powerful and cheap machines(Graviton), its very easy to use a managed database.

**Githu**b**: I chose GH for ci/cd as it provides great flexibilty, also any CI/CD tool can do the job, some of the big players now are GH and Gitlab.

**Datadog**: As explained below I chose Datadog as it provides huge amount of features out of the box, if setup correctly the cost can be controlled. Usually datadog is known to be expensive, the choice is between saving cost or avoiding toil.

**Terraform** - I chose terraform for IAC, because this is one of the most powerfull, and cloud agnostic applications. Extremly flexible and can be integrated easily with other applications, with again ahug comunity.

### Assumptions

- I have assumed the capacity the resources. I have proposed the soultions based normal traffic for an application, nonetheless we have tools like karpentes and horizontal pod autoscalers to help us with scaling in EKS.
- I have explicitly not mentioned any backup stratergies, but for any distributed system, that is essential and AWS comes with many stratergies for it.
- All the solutions provided is suggested keeping security in mind, best practices of security are part of this setup, I can answer any questions around them, if required.
- The self hosted middelware(caches, queuese etc), I did not elaborate on them, but these could be again deployed in the EKS clusters via helm charts or as terraform modules. 
- Access management is not part of the solution, but is an important component to keep in mind.
- VPN setup has not been discussed here, but access to private resources like DB's and EKS clusters should be over a vpn.
- DNS has not been discussed here, but a standard tool like R53 can be used to route traffic to the applications.



### Environments

For the sake of simplicity, I would have 2 environments Develop and Production, these environments will be essentially 2 different AWS accounts to maintain isolation from each other. Both the environments will be identical as much as possible, except for resources, sizing of compute components will be different. But the base layer of both the environments would be identical.

As you can see in the archtecture diagram below, this showcases the base network setup.

- 1 non default vpc in the eu-west-1 region within each AWS account, denoting the vpc's of each environments
- 2 public subnets and 2 private subnets, in the 2 availability zones(eu-wets-1a, eu-west-1b)
- Our EKS clusters would be deployed in the private subnets and will not be public keeping it secure.
- The database would be deployed also in the private subnets which to not expose them to the internet, we could also go another step and deploy the databases in private subnets of their own. This increases the complexity a little as there would need to be communication between the application and database, and there could be some minimal letancy.
- NAT gateways in the public subnets for the resources in the private subnets to be able to get upgrades ans patches from the internet.
- Loadbalancers deployed in the public subnets for traffic flow in and out of the applications.


### Infrastructure-as-Code setup.

I would be chosing terraform as the preferred IAC tool to provision our Infrastructre and manage it further. I would be making use of terraform modules to be able to provision services or resources required by the application to function, for example Databases, S3 buckets, Cloudfront Distrubutions.

- In a separate Github repository I would create terraform modules for each Infrastructure component that is required(base-networking, EKS, RDS, S3, secrets etc). The modules can be re-used and called by the application(FE, BE) repositories to provision resources needed.
- In the repository structure diagram below, I show the basic structure of how the terraform modules would look like. Every component that would be re-used by multiple teams would be managed via terraform modules. These modules avoid repeating code for provisioning a resource multiple times.
- In the application repos(BE or FE), there would be the terraform code that calls these modules to create the resources, they are separated in dedicated folders for each environment, which lets us manage them separatly and reduces chances of interections.
- The terraform stores everything in something called state files, which stores information about the resources it manages, in our case we store them in the respective AWS accounts for each environment.

Also adding some sample terraform code to help you understand a little better.


### CI/CD design

I would be using Github Actions as my CI/CD tool in this case. Below mentioned are the points on how the setup and flow would look like, also considering the simple branching stratergy.

- The best way to deploy to Kubernetes is to use helm charts. Creating a helm template with components required for the application(deployment, service, ingress etc.)
- We will be deploying our application which are already dcokerized, via helm and terraform in combination with GH workflows.
- The simple stages in the workflow would involve
    ```
    building the docker image
    tagging the docker image
    pushing the docker image to ECR
    running a terraform plan(checks changes that need to be deployed)
    running a terraform apply(Deploying the changes)

    ```
- There would be a single workflow that will be able to deploy to both prod and dev using environments feature in Github, using this we can setup secrets and variables per environment and they can be parsed in the workflows as variables.
- One important point to remember, as we are deploying to EKS and our clusters are private, we would be deploying to them using Github Private Runners(not included in the scope here).
- As you can see in the simple flow of deployment to production, with single source of truth main branch.

**FE:**
- Built in CI (GitHub Actions) → optimized static bundle (JS/CSS/HTML)
- Uploaded to S3 bucket per environment (staging, production)
- CloudFront in front of S3 for global edge caching

**Mobile:**
- Built in CI (Fastlane pipelines triggered by GitHub Actions)
- Unit & UI tests in CI
- Build artifacts pushed to Mobile testers

Note: Adding a sample workflow to show how it would look like, mainly for BE, as FE and mobile will be slightly different.


### Observability

As mentioned in the question than there 2 tools being used at the moment and there seems to be a lack of a proper observability setup, I would chose one monitoring tool that can help us here, the favorite choices here would be Datadog or Grafana in combination of some more open source tools(prometheus, loki, alert manager and thanos). For the sake of simplicity and assuming we have a lot of money I will choose Datadog. Datadog is one stop shop for all needs observability. 

- In our EKS clusters we would deploy the datadog agents, that would collect metrics and logs from our applications in the EKS cluster and ship them over to Datadog.
- These agents send over logs and metrics about our applications, and our infrastructure and supporting resources.
- Datadog captures logs, APM traces, Database monitoring, query metrics, audit logs. 
- Creating dashboards and monitors which would send you alerts in case services go down which are evaluated based on thresholds we set.
- Setting up monitors for major endpoints and create alerts or pages in case they go down.
- Metrics that I would monitor 
    ```
    Number of Requests to the application
    http error codes
    Application latency
    RUM (Real User Monitoring) with something like Datadog RUM
    Throughput 
    Error rate 
    Memory usage
    CPU usage
    Slow queries
    Database connections
    Basic Kubernetes Monitoring dashboards(failing pods, resource usage by individual applications)
    ```

**Note:** Grafana in combination with a few other tools can also do all the things datadog can, but there is difficult task to set it up and constantly maintain them, which might not cost a lot in compute but will cost in man hours.

### QA automation & quality gates

- **Pre-deploy:** run e2e suite against staging namespace before Helm upgrade to production.
- **Deploy:** progressive rollout using Helm
- **Post-deploy:** smoke tests on production pods after rollout completes.
- **Quality gates:** block promotion if:
    Any pre-deploy tests fail
    Error rate or latency exceeds SLO during rollout
    New pods fail readiness/liveness probes

A basic flow could look something like this

```
Run unit tests (Rails, React)
Deploy to staging namespace via Helm
Wait for all pods to pass readiness probes
Run e2e tests (Playwright) against staging ingress
On production rollout, run synthetic checks for error rate & latency
Fail/rollback if pod health drops below threshold
After 100% rollout, run smoke tests in all AZs against production ingress
```

## Main KPIs, biggest risks & trade-offs

**KPI's:**
Lead Time:
- With the above setup described and in a perfect scenario, we should be able to deploy to production from a deelopers to Mac in less than an hour.
Deployment Frequency:
- Again with this setup it possible to deploy to production everyday with small changes, keeping testing time to a minimal, as the deployment process is one click.
Change Failure Rate:
- The possibility of code with errors being deployed is almost close to none, as helm does a rolling deploy, which means till the new deployed version does not become healthy, the old version recieves the traffic. Rollback can happen in case incorrect features are shipped and need reverts. But I do not see more than 2 or 3 deployment failures in a month.
Mean Time to Restore:
- With proper alerting and smoke tests in place, it should be fairly easy to detect issues and failures. Once a decision is made to rollback, with helm, just with a single command the release can be rolled back. We should be able to rollback within 30 mins or less.

**Risks**
If some of the below points are handled properly, there will be a minimum amount of risks that we would be encountering.

- Encryption at rest and transit of traffic and data
- Proper secret management at all levels
- Security checks in workflows before code is merged.
- pre-commit hooks to avoid bad code pushes
- Having proper audit trails of actions taken by humans and applications
- Vulnerability scans of  public and private images 
- Regular upgrades and patching of applications and servers.
- Following least privilige access for humans and applications
- Adequeute authenitcation and authorization to api's and applications.
- Implementing WAF rules to safe guard api's and endpoints.

**Trade-Offs**
- Complexity of using EKS for developers and big learning curve
- Helm provider for terraform can be buggy sometimes
- Being heavily reliant on AWS
- Datadog can get expensive if not kept a check on
- Github private runners need to be maintained as they are self hosted
