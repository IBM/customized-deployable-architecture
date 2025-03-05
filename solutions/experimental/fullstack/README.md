# Example fullstack implementation for a Custom Apache workload 

This example illustrates a fullstack implementation of a deployable architecture as opposed to an extension.  A fullstack
deploys all of the necessary dependents in addition to the extension itself.

This example is implemented as terraform.

This example is under construction.


## Considerations developing an extension

An extension needs information in order to leverage a dependent layer.  It needs specific information so that it can deploy into, modify, etc. resources already deployed.
- where does the input values come from?  Two cases to consider.
    - workspace from an existing deployment of a dependency.  This is when the extension is deployed after the fact.
    - output values from dependent module within the same workspace.  This is when the deployment is concurrent with the dependent.

## Considerations developing a deployable architecture

- emit values for resources created both names and ids.  Extensions will need input to query resources and the values help terraform itself sequence modules.
