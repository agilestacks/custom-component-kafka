# Custom Component example - Apache Kafka

The repository contains the following files:

* [hub-component.yaml](hub-component.yaml) Automation Hub deployment manifest, that describes a Custom Component. More details are available in the commented lines of the file in [documentation](https://docs.agilestacks.io/Concepts/Manifest.html)
* [Makefile](Makefile): Custom component implementation in Make. Helm is used to install Apache Kafka release. See commented lines of the Makefile for more information
* [values.yaml.template](values.yaml.template) Kafka Helm chart configuration template. The default template engine is curly for ${}, the others are mustache and commentary, respectively. For more information see templating [documentation](https://docs.agilestacks.io/Concepts/Templating.html)

To deploy the component follow the [instructions](https://docs.agilestacks.io/Tasks/Create%20a%20Custom%20Component.html)
