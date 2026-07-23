#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH

SCRIPT_PATH="/storage/emulated/0/Android/data/li.songe.gkd/files/sh/start.sh"
WAIT_SECONDS=300

wait_for_start_script() {
    elapsed=0

    while [ "$elapsed" -lt "$WAIT_SECONDS" ]; do
        if [ -f "$SCRIPT_PATH" ]; then
            return 0
        fi

        sleep 1
        elapsed=$((elapsed + 1))
    done

    return 1
}

echo "+ [GKD Start Script]"

if [ "$(id -u)" -ne 0 ]; then
    echo "GKD start script requires root: start.sh uses pm grant/appops"
    exit 1
fi

if ! wait_for_start_script; then
    echo "start.sh not ready: $SCRIPT_PATH"
    exit 1
fi

# GKD generated scripts rely on Android's native shell features such as `+=`.
# The PATH-prepended Magisk/AP/KSU `sh` may resolve to a different shell and
# break parsing, so use the system shell explicitly here.
/system/bin/sh "$SCRIPT_PATH"
STATUS=$?

if [ "$STATUS" -eq 0 ]; then
    echo "GKD start script finished"
else
    echo "GKD start script failed: $STATUS"
fi

exit "$STATUS"
