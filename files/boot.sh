#!/usr/bin/env bash

###
## additional bootup things
###

echo 'Doing additional bootup things from `/boot.d/` ...'
bootpath='/boot.d/*.sh'
count=`ls -1 ${bootpath} 2>/dev/null | wc -l`
if [ $count != 0 ]; then
    chmod a+x ${bootpath}
    for f in ${bootpath}; do
        echo "... running ${f}"
        source $f;
        echo "... done with ${f}"
        echo
    done
fi
