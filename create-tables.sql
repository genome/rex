--- Process
CREATE TABLE experimental.process (
    id uuid NOT NULL,
    owner_class_name character varying(255) NOT NULL,
    owner_id character varying(255) NOT NULL,
    status character varying(20) NOT NULL,
    allocation_id character varying(64) NOT NULL,
    CONSTRAINT p_pk PRIMARY KEY (id),
    CONSTRAINT p_a_fk FOREIGN KEY (allocation_id)
        REFERENCES disk.allocation (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)
WITH (
    OIDS=FALSE,
    toast.autovacuum_enabled=FALSE
);
ALTER TABLE experimental.process
  OWNER TO genome;
GRANT ALL ON TABLE experimental.process TO genome;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE experimental.process TO "gms-user";

CREATE INDEX p_owner
ON experimental.process
USING btree (
    owner_class_name COLLATE pg_catalog."default",
    owner_id COLLATE pg_catalog."default"
);

CREATE INDEX p_status
ON experimental.process
USING btree (
    status COLLATE pg_catalog."default"
);

--- Result
CREATE TABLE experimental.result (
    id uuid NOT NULL,
    process_id uuid,
    allocation_id character varying(64) NOT NULL,
    tool_class_name character varying(255) NOT NULL,
    lookup_hash character varying(32) NOT NULL,
    test_name character varying(255),

    CONSTRAINT r_pk PRIMARY KEY (id),
    CONSTRAINT r_p_fk FOREIGN KEY (process_id)
        REFERENCES experimental.process (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT r_a_fk FOREIGN KEY (allocation_id)
        REFERENCES disk.allocation (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT r_lookup UNIQUE (lookup_hash, tool_class_name, test_name)
)
WITH (
    OIDS=FALSE,
    toast.autovacuum_enabled=FALSE
);
ALTER TABLE experimental.result
  OWNER TO genome;
GRANT ALL ON TABLE experimental.result TO genome;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE experimental.result TO "gms-user";

CREATE INDEX r_test_name
ON experimental.result
USING btree (
    test_name COLLATE pg_catalog."default"
);

--- Result Inputs
CREATE TABLE experimental.result_input (
    id uuid NOT NULL,
    result_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    value_class_name character varying(255),
    value_id character varying(1024),
    CONSTRAINT ri_pk PRIMARY KEY (id),
    CONSTRAINT ri_r_fk FOREIGN KEY (result_id)
        REFERENCES experimental.result (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT ri_id_name UNIQUE (result_id, name)
)
WITH (
    OIDS=FALSE,
    toast.autovacuum_enabled=FALSE
);
ALTER TABLE experimental.result_input
  OWNER TO genome;
GRANT ALL ON TABLE experimental.result_input TO genome;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE experimental.result_input TO "gms-user";

CREATE INDEX ri_name
ON experimental.result_input
USING btree (
    name COLLATE pg_catalog."default"
);

CREATE INDEX ri_value
ON experimental.result_input
USING btree (
    value_id COLLATE pg_catalog."default",
    value_class_name COLLATE pg_catalog."default"
);

--- Result Outputs
CREATE TABLE experimental.result_output (
    id uuid NOT NULL,
    result_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    value_class_name character varying(255),
    value_id character varying(1024),
    CONSTRAINT ro_pk PRIMARY KEY (id),
    CONSTRAINT ro_r_fk FOREIGN KEY (result_id)
        REFERENCES experimental.result (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT ro_id_name UNIQUE (result_id, name)
)
WITH (
    OIDS=FALSE,
    toast.autovacuum_enabled=FALSE
);
ALTER TABLE experimental.result_output
  OWNER TO genome;
GRANT ALL ON TABLE experimental.result_output TO genome;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE experimental.result_output TO "gms-user";

CREATE INDEX ro_name
ON experimental.result_output
USING btree (
    name COLLATE pg_catalog."default"
);

CREATE INDEX ro_value
ON experimental.result_output
USING btree (
    value_id COLLATE pg_catalog."default",
    value_class_name COLLATE pg_catalog."default"
);
