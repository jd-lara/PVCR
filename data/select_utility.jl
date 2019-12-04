if @isdefined(cnfl) && isassigned(cnfl, 1) && cnfl[1]
    pv_output = cnfl_pv_output
    PVRes = PVRes_CNFL
    PVComInd = PVComInd_CNFL
    PVTMT = PVTMT_CNFL
else
    pv_output = ice_pv_output
    PVRes = PVRes_ICE
    PVComInd = PVComInd_ICE
    PVTMT = PVTMT_ICE
end