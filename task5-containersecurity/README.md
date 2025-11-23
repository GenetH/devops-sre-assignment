# Task 5: Container Security and Compliance Automation

## Objective  
Automate container image security scanning and compliance checks within the CI/CD pipeline. This ensures that only secure and trusted images are deployed to production.

## Production Requirements Implemented  
- Vulnerability scanning using **Trivy** (a standard in the industry).
- Compliance checks using **OPA (Open Policy Agent)**.
- The pipeline blocks deployments if:
  - Critical vulnerabilities are present.
  - The image violates production policies (for example, runs as root, lacks labels, or has no tag pinning).
- Detailed reports are saved as artifacts.
- A fail-fast method ensures unsafe images do not reach production.

## Tools Used  
### ✔ Trivy  
Used for vulnerability scanning.  
Reason: It is fast, lightweight, and widely used in production pipelines.

### ✔ OPA (Conftest)  
Used to enforce custom security rules.  
Reason: It is flexible, declarative, and works well with GitLab CI and Jenkins.

## Execution in Pipeline  
1. The developer commits code.  
2. The build pipeline creates a container image.  
3. **Trivy Scan Stage**  
   - Scans OS and application packages.  
   - Creates JSON and HTML reports.  
   - Fails the pipeline if high or critical issues are found.

4. **Policy Enforcement Stage (OPA)**  
   - Checks the Dockerfile for best practices.  
   - Validates labels, non-root user, version pinning, and no latest tag.  
   - Blocks deployment if any rule is broken.

5. Only compliant images are pushed to the registry.

## Reporting & Blocking  
- PDF, HTML, and JSON reports are saved as CI artifacts.  
- The merge request shows pass or fail results.  
- The pipeline stops right away on:  
  - Critical vulnerabilities.  
  - Non-compliant configurations.

## Production Notes  
- The Trivy database updates automatically every day.  
- Policies are stored in version control for transparency.  
- The pipeline integrates with the container registry (GitHub, GitLab, ECR, Harbor).