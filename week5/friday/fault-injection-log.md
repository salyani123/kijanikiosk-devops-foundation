# CI Pipeline Fault Injection Log

| Stage Faulted | Observed Downstream Behaviour | Design Rationale |
| :--- | :--- | :--- |
| **Lint** | The pipeline stopped immediately. Build, Verify, Archive, and Publish were skipped. | Failing fast at the lint stage saves compute resources because there is no point trying to build code that has basic syntax errors. |
| **Build** | Lint passed, but the pipeline halted at Build. Verify, Archive, and Publish were skipped. | If the code cannot compile or build properly, there is no working app to test. Stopping here prevents the pipeline from testing a broken build. |
| **Verify (Test)** | Lint and Build passed, but Test failed. Archive and Publish were skipped. | We do not want to package or publish an artifact that fails its unit tests or has security vulnerabilities, as this would deliver a broken product to users. |
| **Archive** | Lint, Build, and Verify passed, but Archive failed. Publish was skipped. | If the pipeline fails to bundle the application into a deployable artifact, there is nothing valid to send to the Nexus registry. |
| **Publish** | All previous stages passed, but Publish failed. | If the credentials are wrong or Nexus is down, the pipeline must fail to alert the team that the approved artifact was never actually delivered to the registry. |