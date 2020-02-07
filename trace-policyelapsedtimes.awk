# gawk!
BEGIN{

    current_ts = ""
    policy_current_ts = ""

    pol_state = "OFF"
    point_end_ts=""
}

function timestamp2epoch( ts ){

    match( ts, /^([[:digit:]]{2})-([[:digit:]]{2})-([[:digit:]]{2}) ([[:digit:]]{2}):([[:digit:]]{2}):([[:digit:]]{2}):([[:digit:]]{3})/, a )
    #print  "20" a[3] " " a[2] " " a[1] " " a[4] " " a[5] " " a[6]
    
    return mktime( "20" a[3] " " a[2] " " a[1] " " a[4] " " a[5] " " a[6] ) a[7]
}

/<DebugId>/{
    match( $0, /<DebugId>(.+)<\/DebugId>/, m )

    current_request = m[1]
}
# /<Point id="Execution">/
/<\/Point>/{ 
    if( pol_state == "INPOL" ){
        pol_state="POINTEND"
    }
}
/<Property name="stepDefinition-name">/{
    
    # <Property name="stepDefinition-name">LookupCacheGetEAIErrorCode</Property>
    match( $0, /<Property name="stepDefinition-name">(.+)<\/Property>/, m )
    current_policy = m[1]
    
    current_policy_ts = current_ts
    pol_state="INPOL"
}

/<Timestamp>/{
    match( $0, /<Timestamp>(.+)<\/Timestamp>/, m )
   
    current_ts = timestamp2epoch(m[1])
    
    
    if( pol_state == "POINTEND" ){
        # emit policy duration
        print current_request, current_policy, current_ts - current_policy_ts
    
        # clear pol_state
        pol_state = "OFF"
    }
}
