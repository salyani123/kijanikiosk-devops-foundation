# KijaniKiosk Deployment Recovery Procedure

If a deployment fails, execute the following steps immediately:
1. Halt the Pipeline: Manually pause the CI/CD pipeline to prevent any further automated deployments.
2. Revert to Last Known Good State: Roll back the production environment to the previously tagged release version.
3. Isolate the Failure: Do not restart the failed services. Instead, extract and preserve the apllication and system logs for the failure winddow.
4. Verify Rollback Health: Run the health check endpoint to confirm that the platform is stable for KijaniKiosk retailers.
5. Post-Incident Report: Document the root cause in the incedent tracker and implement a pipeline guardrail before attempting the next deployment.
