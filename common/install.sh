# Setup "vanilla" phenotype.db SQLite database, pre-patched with AA-Tweaker.
# Used to make Android Auto + apps work correctly, can be patched further with AA-Tweaker / manually.
ui_print ""

GMS_PATH=/data/data/com.google.android.gms/
PHENOTYPE_DB_PATH="$GMS_PATH"databases/
COPY_PHENOTYPE_DB="false"

if [ "$COPY_PHENOTYPE_DB" = "true" ] ; then
  ui_print "   Creating initial 'phenotype.db'..."

  GMS_OWNER=$(stat -c '%U' "$GMS_PATH")
  GMS_GROUP=$(stat -c '%G' "$GMS_PATH")

  # Create the folder if missing + Inject the phenotype.db file
  mkdir -p "$PHENOTYPE_DB_PATH"
  cp "$MODPATH""$PHENOTYPE_DB_PATH"phenotype.db \
      "$PHENOTYPE_DB_PATH"phenotype.db

  # Restore correct ownership
  chown -R "$GMS_OWNER" "$PHENOTYPE_DB_PATH"
  chgrp -R "$GMS_GROUP" "$PHENOTYPE_DB_PATH"
fi

AA_PATH=/data/data/com.google.android.projection.gearhead/
PHENOTYPE_PB_PATH="$AA_PATH"files/phenotype/shared/

if [ ! -f "${PHENOTYPE_PB_PATH}com.google.android.projection.gearhead.pb" ] ; then
    # Setup "vanilla" com.google.android.projection.gearhead.pb binary file.
    # CoolWalk requirement, file cannot be modified..
    ui_print "   Setting up additional dependencies..."
    AA_OWNER=$(stat -c '%U' "$AA_PATH")
    AA_GROUP=$(stat -c '%U' "$AA_PATH")

    # Create the folder if missing + Inject the binary .pb file
    mkdir -p "$PHENOTYPE_PB_PATH"
    cp "$MODPATH""$PHENOTYPE_PB_PATH"com.google.android.projection.gearhead.pb \
        "$PHENOTYPE_PB_PATH"com.google.android.projection.gearhead.pb

    # Restore correct ownership
    chown -R "$AA_OWNER" "$AA_PATH"files/
    chgrp -R "$AA_GROUP" "$AA_PATH"files/
fi