module RealmUrl exposing (create, fromIds, parse, parseIds)

import FarmUrl


create =
    FarmUrl.create << Debug.log "RealmUrl is deprecated. Use FarmUrl"


fromIds =
    FarmUrl.fromIds << Debug.log "RealmUrl is deprecated. Use FarmUrl"


parse =
    FarmUrl.parse << Debug.log "RealmUrl is deprecated. Use FarmUrl"


parseIds =
    FarmUrl.parseIds << Debug.log "RealmUrl is deprecated. Use FarmUrl"
