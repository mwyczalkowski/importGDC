Download process:

start_step.sh UUID1 UUID2 ...
    Calls:
        GDC_import.sh UUID
            Calls:
                `docker process_GDC_uuid.sh UUID`
                Calls:
                    gdc-client UUID
                Indexes and flagstat as appropriate

TODO: this is more complicated that it needs to be, and GDC_import.sh can also loop over a list of UUID
Suggestion going forward is to do away with start_step.sh (which was motivated by workflow with multiple 
steps)

TODO: understand where logs / stderr / stdout go during parallel runs.  Can't find them currently
See https://stackoverflow.com/questions/41451243/gnu-parallel-stderr-with-files-or-sensible-results-tree
maybe use --results
