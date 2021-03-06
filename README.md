topbeat-quickstart
==================

A quick start kit for [Topbeat](https://www.elastic.co/jp/downloads/beats/topbeat) with Elasticsearch and Kibana

Supported Topbeat version:  1.3.1

Usage
-----

1.  Check out the repository.

    ```sh
    $ git clone https://github.com/dceoy/topbeat-quickstart.git
    $ cd topbeat-quickstart
    ```

2.  Run containers for Elasticsearch and Kibana using [Docker Compose](https://docs.docker.com/compose/).
    (If you use existing hosts for them, skip this step.)

    ```sh
    $ docker-compose up -d
    ```

3.  Prepare Elasticsearch.

    ```sh
    $ ./prepare.sh
    ```

    By default, this configures an Elasticsearch host at `localhost:9200`.
    If you use an existing Elasticsearch host, do as follows:

    ```sh
    $ ./prepare.sh --elasticsearch your.own.elasticsearch.host:9200
    ```

4.  Start Topbeat.

    ```sh
    $ sudo ./topbeat -e -c topbeat.yml -d 'publish'
    ```

    If you run Topbeat on another host, set your Elasticsearh host at `hosts` in `topbeat.yml` before starting it.

5.  Access `http://localhost:5601` or your own Kibana host using a web browser to see infrastructure metrics.
