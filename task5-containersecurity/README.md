# Task 5: Container Security and Compliance Automation

## Objective
Automate container image security scanning and compliance checks inside the CI/CD pipeline to ensure only secure and trusted images are deployed into production.

## Production Requirements Implemented
- Vulnerability scanning using **Trivy** (industry-standard).
- Compliance/policy checks using **OPA (Open Policy Agent)**.
- Pipeline blocks deployments if:
  - Critical vulnerabilities exist.
  - Image violates production policies (e.g., runs as root, missing labels, no tag pinning).
- Detailed reports are stored as artifacts.
- Fail-fast behavior ensures unsafe images never reach production.

## Tools Used
### ✔ Trivy
Used for vulnerability scanning.  
Reason: Fast, lightweight, widely adopted in production pipelines.

### ✔ OPA (Conftest)
Used for enforcement of custom security rules.  
Reason: Flexible, declarative, compatible with GitLab CI and Jenkins.

## Execution in Pipeline
1. Developer commits code.
2. Build pipeline creates a container image.
3. **Trivy Scan Stage**
   - Scans OS & application packages.
   - Generates JSON + HTML reports.
   - Fails pipeline on High/Critical issues.

4. **Policy Enforcement Stage (OPA)**
   - Checks Dockerfile for best-practices.
   - Validates labels, non-root user, version pinning, no latest tag.
   - Blocks deployment if any rule is violated.

5. Only compliant images are pushed to registry.

## Reporting & Blocking
- PDF/HTML/JSON reports stored as CI artifacts.
- Merge request shows pass/fail results.
- Pipeline stops immediately on:
  - Critical vulnerabilities.
  - Non-compliant configuration.

## Production Notes
- Trivy database auto-updates daily.
- Policies stored in version control for transparency.
- Pipeline integrated with container registry (GitHub, GitLab, ECR, Harbor).
