# Week 5 CI Pipeline: Reflection

### 1. Requirement Tension
I found a conflict between the rule to not use hardcoded values and the strict rules for the `.npmrc` file we use to log into Nexus. The project said the Nexus URL had to be an environment variable. But the npm tool needs the full URL for the registry link, and it completely breaks if you include "http://" in the password section. When I tried to use one big URL variable for both, it failed with a 401 error. To fix this, I split the variables into a host part and a path part at the top of the Jenkinsfile. This let me combine them differently for each line, following the no-hardcoding rule without breaking the pipeline's authentication.

### 2. Translation
**Original Sentence (for Nia):** 
"Since time is valuable for our team, we designed the pipeline to run the functional tests and the security checks at the exact same time during the Verify stage."

**Technical Translation (for Osei):** 
"We used parallel blocks in the Verify stage to run `npm test` and `npm audit` concurrently, which helps reduce the total build time."

**Explanation:** Both versions explain that we are running the tests and security checks at the exact same time to speed things up. The difference is the audience. The board version talks about how time is valuable for the business. The technical version focuses on the exact commands used (`npm test` and `npm audit`) and uses developer terms like "parallel blocks" and "build time."

### 3. Scaling
If our team grows from 4 to 40 developers, the first thing that will break is our Jenkins server running out of resources. Right now, the whole pipeline runs on just one local Jenkins controller. If 40 developers are constantly pushing code and triggering builds at the same time, this single machine will get completely overwhelmed. The builds will just wait in a long queue, which ruins the quick feedback CI is supposed to provide. To fix this, we would need to set up Jenkins to use worker nodes. The main controller would just manage the queue, but it would send the actual build jobs to other machines to handle the heavy lifting.