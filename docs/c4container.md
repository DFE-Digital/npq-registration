[< Back to Navigation](../README.md)

# C4 Container model

Internally we have web and worker Kubernetes containers nodes, with the web
containers accessed via a CDN backed onto an nginx kubernetes ingress. These are
backed by Azure managed Postgres, Redis and blob storage services.

Externally we integrate with
* the TeacherAuth service provided by the TRS service, which itself then integrates with the GOV.UK One Login service
* we provide certificate information to the TRS service via an internal API
* we request TRN allocation for new TeacherAuth users via a TRS API, via a per-user OAuth access token
* we are notified of user changes via signed webhooks we provide to TRS
* we send emails out using the GOV.UK Notify service

Below is a C4 Container diagram for the NPQ service

```mermaid
C4Container
  title Cloud Infrastructure Platform

  System_Ext("lp1", "Lead Provider 1", "Lead Provider API", "Bearer Token secured API for Lead Providers to interact with NPQ service")
  System_Ext("lp2", "Lead Provider 2", "Lead Provider API", "Bearer Token secured API for Lead Providers to interact with NPQ service")

  Person(participant, "Participant", "User registering for NPQ")
  Person(staff, "Admin user", "Admin User")

  Container_Boundary(cip, "DfE Cloud Infrastructure Platform") {
    System("cdn", "CDN", "Azure FrontDoor")

    Container_Boundary(internal, "CIP services") {
      SystemDb("db", "Database", "Azure hosted Postgres")
      SystemDb("cache", "Cache", "Azure hosted Redis")
      System("blob", "Storage", "Azure Blob storage")
    }

    Container_Boundary(k8s, "Kubernetes Cluster") {
      Container(lb, "Load Balancer", "NGinx,  K8s Ingress")
      Container(web, "Web App", "Rails, Docker container")
      Container(worker, "Job Queue", "Rails, Docker container", "same Rails app running background jobs queue")
    }

    Container_Boundary(trs, "TRS services") {
      System_Ext(teacherauth, "TeacherAuth", "Auth service")
      System_Ext(trsapi, "TRS API service", "API data service")
    }
  }

  Container_Boundary(gdsonelogin, "GDS services") {
    System_Ext("onelogin", "One Login", "Auth service")
    System_Ext("notify", "Email service", "GovUK Notify")
  }

  Rel(cdn,lb, "HTTPS")
  Rel(lb,web, "HTTPS")
  Rel(web,db, "PSQL")
  Rel(worker,db, "PSQL")
  Rel(web,cache, "Redis")
  Rel(worker,cache, "Redis")
  Rel(web,blob, "HTTPS")
  Rel(worker,blob, "HTTPS")
  Rel(lp1,cdn,  "JSON-API service", "HTTPS bearer  token")
  Rel(lp2,cdn, "JSON-API service", "HTTPS bearer token")
  Rel(participant,cdn, "Web", "HTTPS")
  Rel(staff,cdn, "Web", "HTTPS")
  Rel(teacherauth, cdn,"OAuth")
  Rel(onelogin,teacherauth,"OAuth")
  Rel(participant,onelogin,"OAuth")
  Rel(participant,teacherauth,"OAuth")
  Rel(web, trsapi,"Fetch users teaching record", "per-user OAuth access token")
  Rel(worker, trsapi,"Fetch users teaching record", "per-user OAuth access token")
  Rel(trsapi,cdn,"HTTPS", "HTTPS bearer token")
  Rel(teacherauth,cdn,"HTTPS", "Signed webhook callback")
  Rel(web,notify, "Sending email", "JSON over HTTPS, bearer token")
  Rel(worker,notify, "Sending email", "JSON over HTTPS, bearer token")

  UpdateLayoutConfig($c4ShapeInRow="4", $c4BoundaryInRow="5")
```
