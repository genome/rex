--- Checkpoint
CREATE TABLE experimental.checkpoint (
    id uuid NOT NULL,
    lookup_hash character varying(32) NOT NULL,
    tool_class_name character varying(255) NOT NULL,
    test_name character varying(255),
    allocation_id character varying(64) NOT NULL,
    software_revision character varying(1024),
    CONSTRAINT r_pk PRIMARY KEY (id),
    CONSTRAINT r_a_fk FOREIGN KEY (allocation_id)
        REFERENCES disk.allocation (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT r_lookup_hash UNIQUE (lookup_hash, tool_class_name, test_name)
)
WITH (
    OIDS=FALSE,
    toast.autovacuum_enabled=FALSE
);
ALTER TABLE experimental.checkpoint
  OWNER TO genome;
GRANT ALL ON TABLE experimental.checkpoint TO genome;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE experimental.checkpoint TO "gms-user";

CREATE INDEX r_test_name
ON experimental.checkpoint
USING btree (
    test_name COLLATE pg_catalog."default"
);


--- Result Inputs
-- CREATE TABLE experimental.result_input (
--     id uuid NOT NULL,
--     result_id uuid NOT NULL,
--     name character varying(255) NOT NULL,
--     value_class_name character varying(255),
--     value_id character varying(1024),
--     CONSTRAINT ri_pk PRIMARY KEY (id),
--     CONSTRAINT ri_r_fk FOREIGN KEY (result_id)
--         REFERENCES experimental.result (id) MATCH SIMPLE
--         ON UPDATE NO ACTION
--         ON DELETE NO ACTION,
--     CONSTRAINT ri_id_name UNIQUE (result_id, name)
-- )
-- WITH (
--     OIDS=FALSE,
--     toast.autovacuum_enabled=FALSE
-- );
-- ALTER TABLE experimental.result_input
--   OWNER TO genome;
-- GRANT ALL ON TABLE experimental.result_input TO genome;
-- GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE experimental.result_input TO "gms-user";
-- 
-- CREATE INDEX ri_name
-- ON experimental.result_input
-- USING btree (
--     name COLLATE pg_catalog."default"
-- );
-- 
-- CREATE INDEX ri_value
-- ON experimental.result_input
-- USING btree (
--     value_id COLLATE pg_catalog."default",
--     value_class_name COLLATE pg_catalog."default"
-- );
