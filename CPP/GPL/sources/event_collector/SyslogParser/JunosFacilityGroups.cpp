#include "JunosFacilityGroups.h"

class ACCTGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "ACCT" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "ACCT_ACCOUNTING_FERROR",
                "ACCT_ACCOUNTING_FOPEN_ERROR",
                "ACCT_ACCOUNTING_SMALL_FILE_SIZE",
                "ACCT_BAD_RECORD_FORMAT",
                "ACCT_CU_RTSLIB_ERROR",
                "ACCT_FORK_ERR",
                "ACCT_FORK_LIMIT_EXCEEDED",
                "ACCT_GETHOSTNAME_ERROR",
                "ACCT_MALLOC_FAILURE",
                "ACCT_UNDEFINED_COUNTER_NAME",
                "ACCT_XFER_FAILED",
                "ACCT_XFER_POPEN_FAIL"
            };
            return names;
        }
};

class ALARMDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "ALARMD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "ALARMD_CONFIG_ACCESS_ERROR",
                "ALARMD_CONFIG_CLOSE_ERROR",
                "ALARMD_CONFIG_PARSE_ERROR",
                "ALARMD_CONFIG_RECONFIG_ERROR",
                "ALARMD_CONNECTION_FAILURE",
                "ALARMD_DECODE_ALARM_OBJECT_ERROR",
                "ALARMD_EXISTS",
                "ALARMD_EXISTS_TERM_OTHER",
                "ALARMD_IFDALARM_TYPE_ERROR",
                "ALARMD_IFDEV_RTSLIB_FAILURE",
                "ALARMD_IPC_MSG_ERROR",
                "ALARMD_IPC_MSG_WRITE_ERROR",
                "ALARMD_IPC_UNEXPECTED_CONN",
                "ALARMD_IPC_UNEXPECTED_MSG",
                "ALARMD_MEM_ALLOC_FAILURE",
                "ALARMD_MGR_CONNECT",
                "ALARMD_MULTIPLE_ALARM_BIT_ERROR",
                "ALARMD_PIDFILE_OPEN",
                "ALARMD_PIPE_WRITE_ERROR",
                "ALARMD_SOCKET_CREATE",
                "ALARMD_UNEXPECTED_EXIT"
            };
            return names;
        }
};

class ANALYZERGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "ANALYZER" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
            "ANALYZER_INPUT_INTERFACES_LIMIT"
            };
            return names;
        }
};

class ANCPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "ANCPD" );
        }

        vector<string>& GetFacilityNames()
        {
          static vector<string> names =
          {
              "ANCPD_COMMAND_OPTIONS",
          };
          return names;
        }
};

class APPIDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "APPID" );
        }

        vector<string>& GetFacilityNames()
        {
          static vector<string> names =
          {
              "APPID_SIGNATURE_LICENSE_EXPIRED"
          };
          return names;
        }
};

class APPIDDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "APPIDD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "APPIDD_APPPACK_DOWNLOAD_RESULT",
                "APPIDD_APPPACK_INSTALL_RESULT",
                "APPIDD_APPPACK_UNINSTALL_RESULT",
                "APPIDD_DAEMON_INIT_FAILED",
                "APPIDD_INTERNAL_ERROR",
                "APPIDD_SCHEDULED_UPDATE_FAILED"
            };
            return names;
        }
};

class APPTRACKGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "APPTRACK" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "APPTRACK_SESSION_APP_UPDATE",
                "APPTRACK_SESSION_APP_UPDATE_LS",
                "APPTRACK_SESSION_CLOSE",
                "APPTRACK_SESSION_CLOSE_LS",
                "APPTRACK_SESSION_CREATE",
                "APPTRACK_SESSION_CREATE_LS",
                "APPTRACK_SESSION_VOL_UPDATE",
                "APPTRACK_SESSION_VOL_UPDATE_LS"
            };
            return names;
        }
};

class ASPGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "ASP" );
        }

        vector<string>& GetFacilityNames()
        {
              static vector<string> names =
              {
                  "ASP_COS_RULE_MATCH",
                  "ASP_IDS_HOST_RATE",
                  "ASP_IDS_HOST_RATE_APP",
                  "ASP_IDS_INV_CLEAR_QUERY",
                  "ASP_IDS_INV_CLEAR_QUERY_VER",
                  "ASP_IDS_INV_SHOW_QUERY",
                  "ASP_IDS_INV_SHOW_QUERY_VER",
                  "ASP_IDS_LIMIT_FLOW_RATE_BY_DEST",
                  "ASP_IDS_LIMIT_FLOW_RATE_BY_PAIR",
                  "ASP_IDS_LIMIT_FLOW_RATE_BY_SRC",
                  "ASP_IDS_LIMIT_OPEN_FLOWS_BY_DEST",
                  "ASP_IDS_LIMIT_OPEN_FLOWS_BY_PAIR",
                  "ASP_IDS_LIMIT_OPEN_FLOWS_BY_SRC",
                  "ASP_IDS_LIMIT_PKT_RATE_BY_DEST",
                  "ASP_IDS_LIMIT_PKT_RATE_BY_PAIR",
                  "ASP_IDS_LIMIT_PKT_RATE_BY_SRC",
                  "ASP_IDS_NO_MEM_SHOW_CMD",
                  "ASP_IDS_NULL_CLEAR_QUERY",
                  "ASP_IDS_NULL_SHOW_QUERY",
                  "ASP_IDS_RULE_MATCH",
                  "ASP_IDS_SYN_COOKIE_OFF",
                  "ASP_IDS_SYN_COOKIE_ON",
                  "ASP_IDS_TCP_SYN_ATTACK",
                  "ASP_L2TP_MESSAGE_INCOMPLETE",
                  "ASP_L2TP_NO_MEM",
                  "ASP_L2TP_OBJ_CAC_FAIL",
                  "ASP_L2TP_STATS_BULK_QUERY_FAILED",
                  "ASP_L2TP_STATS_VERSION_INVALID",
                  "ASP_L2TP_TUN_GRP_ADD_FAIL_ALLOC",
                  "ASP_L2TP_TUN_GRP_ADD_FAIL_EXISTS",
                  "ASP_L2TP_TUN_GRP_CHG_FAIL_ALLOC",
                  "ASP_L2TP_TUN_GRP_CHG_FAIL_INVLD",
                  "ASP_L2TP_TUN_GRP_DEL_FAIL_INVLD",
                  "ASP_NAT_OUTOF_ADDRESSES",
                  "ASP_NAT_OUTOF_PORTS",
                  "ASP_NAT_POOL_RELEASE",
                  "ASP_NAT_PORT_BLOCK_ALLOC",
                  "ASP_NAT_PORT_BLOCK_RELEASE",
                  "ASP_NAT_RULE_MATCH",
                  "ASP_PGCP_IPC_MSG_WRITE_FAILED",
                  "ASP_PGCP_IPC_PIPE_WRITE_FAILED",
                  "ASP_SFW_ALG_LEVEL_ADJUSTED",
                  "ASP_SFW_ALG_PROMOTION_FAILED",
                  "ASP_SFW_APP_MSG_TOO_LONG",
                  "ASP_SFW_CHANGE_INACTIVITY_TIMER",
                  "ASP_SFW_CREATE_ACCEPT_FLOW",
                  "ASP_SFW_CREATE_DISCARD_FLOW",
                  "ASP_SFW_CREATE_REJECT_FLOW",
                  "ASP_SFW_DELETE_FLOW",
                  "ASP_SFW_FTP_ACTIVE_ACCEPT",
                  "ASP_SFW_FTP_PASSIVE_ACCEPT",
                  "ASP_SFW_ICMP_ERROR_DROP",
                  "ASP_SFW_ICMP_HEADER_LEN_ERROR",
                  "ASP_SFW_ICMP_PACKET_ERROR_LENGTH",
                  "ASP_SFW_IP_FRAG_ASSEMBLY_TIMEOUT",
                  "ASP_SFW_IP_FRAG_OVERLAP",
                  "ASP_SFW_IP_OPTION_DROP_PACKET",
                  "ASP_SFW_IP_PACKET_CHECKSUM_ERROR",
                  "ASP_SFW_IP_PACKET_DST_BAD",
                  "ASP_SFW_IP_PACKET_FRAG_LEN_INV",
                  "ASP_SFW_IP_PACKET_INCORRECT_LEN",
                  "ASP_SFW_IP_PACKET_LAND_ATTACK",
                  "ASP_SFW_IP_PACKET_NOT_VERSION_4",
                  "ASP_SFW_IP_PACKET_PROTOCOL_ERROR",
                  "ASP_SFW_IP_PACKET_SRC_BAD",
                  "ASP_SFW_IP_PACKET_TOO_LONG",
                  "ASP_SFW_IP_PACKET_TOO_SHORT",
                  "ASP_SFW_IP_PACKET_TTL_ERROR",
                  "ASP_SFW_NEW_POLICY",
                  "ASP_SFW_NO_IP_PACKET",
                  "ASP_SFW_NO_POLICY",
                  "ASP_SFW_NO_RULE_DROP",
                  "ASP_SFW_PING_DUPLICATED_SEQNO",
                  "ASP_SFW_PING_MISMATCHED_SEQNO",
                  "ASP_SFW_PING_OUTOF_SEQNO_CACHE",
                  "ASP_SFW_POLICY_REJECT",
                  "ASP_SFW_RULE_ACCEPT",
                  "ASP_SFW_RULE_DISCARD",
                  "ASP_SFW_RULE_REJECT",
                  "ASP_SFW_SYN_DEFENSE",
                  "ASP_SFW_TCP_BAD_SYN_COOKIE_RESP",
                  "ASP_SFW_TCP_FLAGS_ERROR",
                  "ASP_SFW_TCP_HEADER_LEN_ERROR",
                  "ASP_SFW_TCP_NON_SYN_FIRST_PACKET",
                  "ASP_SFW_TCP_PORT_ZERO",
                  "ASP_SFW_TCP_RECONSTRUCT_DROP",
                  "ASP_SFW_TCP_SCAN",
                  "ASP_SFW_TCP_SEQNO_AND_FLAGS_ZERO",
                  "ASP_SFW_TCP_SEQNO_ZERO_FLAGS_SET",
                  "ASP_SFW_UDP_HEADER_LEN_ERROR",
                  "ASP_SFW_UDP_PORT_ZERO",
                  "ASP_SFW_UDP_SCAN",
                  "ASP_SFW_VERY_BAD_PACKET",
                  "ASP_SVC_SET_MAX_FLOWS_EXCEEDED"
              };
              return names;
        }
};

class AUDITDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "AUDITD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "AUDITD_RADIUS_AV_ERROR",
                "AUDITD_RADIUS_OPEN_FAILED",
                "AUDITD_RADIUS_REQ_CREATE_FAILED",
                "AUDITD_RADIUS_REQ_DROPPED",
                "AUDITD_RADIUS_REQ_SEND_ERROR",
                "AUDITD_RADIUS_REQ_TIMED_OUT",
                "AUDITD_RADIUS_SERVER_ADD_ERROR",
                "AUDITD_SOCKET_FAILURE"
            };
            return names;
        }
};

class AUTHDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "AUTHD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "AUTHD_AUTH_CREATE_FAILED",
                "AUTHD_RADIUS_GETHOSTNAME_FAILED",
                "AUTHD_SERVER_INIT_BIND_FAIL",
                "AUTHD_SERVER_INIT_LISTEN_FAIL"
            };
            return names;
        }
};

class AUTOCONFDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "AUTOCONFD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "AUTOCONFD_AUTHENTICATE_LICENSE"
            };
            return names;
        }
};

class AUTODGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "AUTOD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "AUTOD_BIND_FAILURE",
                "AUTOD_HOSTNAME_EXPANSION_FAILURE",
                "AUTOD_RECV_FAILURE",
                "AUTOD_RES_MKQUERY_FAILURE",
                "AUTOD_SEND_FAILURE",
                "AUTOD_SOCKET_CREATE_FAILURE"
            };
            return names;
        }
};

class AVGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "AV" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "AV_PATTERN_GET_FAILED",
                "AV_PATTERN_KEY_EXPIRED",
                "AV_PATTERN_KL_CHECK_FAILED",
                "AV_PATTERN_TOO_BIG",
                "AV_PATTERN_UPDATED",
                "AV_PATTERN_WRITE_FS_FAILED",
                "AV_SCANNER_READY"
            };
            return names;
        }
};

class BFDDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "BFDD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "BFDD_MIRROR_ERROR",
                "BFDD_MIRROR_VERSION_MISMATCH",
                "BFDD_READ_ERROR",
                "BFDD_TRAP_MHOP_STATE_DOWN",
                "BFDD_TRAP_MHOP_STATE_UP",
                "BFDD_TRAP_SHOP_STATE_DOWN",
                "BFDD_TRAP_SHOP_STATE_UP",
                "BFDD_TRAP_STATE_DOWN",
                "BFDD_TRAP_STATE_UP",
                "BFDD_WRITE_ERROR"
            };
            return names;
        }
};

class Group : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "BOOTPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "BOOTPD_ARG_ERR",
                "BOOTPD_BAD_ID",
                "BOOTPD_BOOTSTRING",
                "BOOTPD_CONFIG_ERR",
                "BOOTPD_CONF_OPEN",
                "BOOTPD_DUP_PIC_SLOT",
                "BOOTPD_DUP_REV",
                "BOOTPD_DUP_SLOT",
                "BOOTPD_HWDB_ERROR",
                "BOOTPD_MODEL_CHK",
                "BOOTPD_NEW_CONF",
                "BOOTPD_NO_BOOTSTRING",
                "BOOTPD_NO_CONFIG",
                "BOOTPD_PARSE_ERR",
                "BOOTPD_REPARSE",
                "BOOTPD_SELECT_ERR",
                "BOOTPD_TIMEOUT"
            };
            return names;
        }
};

class CFMDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "CFMD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "CFMD_CCM_DEFECT_CROSS_CONNECT",
                "CFMD_CCM_DEFECT_ERROR",
                "CFMD_CCM_DEFECT_MAC_STATUS",
                "CFMD_CCM_DEFECT_NONE",
                "CFMD_CCM_DEFECT_RDI",
                "CFMD_CCM_DEFECT_RMEP",
                "CFMD_CCM_DEFECT_UNKNOWN",
                "CFMD_PPM_READ_ERROR",
                "CFMD_PPM_WRITE_ERROR"
            };
            return names;
        }
};

class CHASSISDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "CHASSISD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "CHASSISD_ACQUIRE_MASTERSHIP",
                "CHASSISD_ANTICF_PIM_CHECK_FAILED",
                "CHASSISD_ANTICF_RE_CHECK_FAILED",
                "CHASSISD_ANTICF_RE_ROM_READ_FAIL",
                "CHASSISD_ANTICF_RE_SHA_READ_FAIL",
                "CHASSISD_ANTICF_ROM_READ_FAILED",
                "CHASSISD_ANTICF_SHA_READ_FAILED",
                "CHASSISD_ARGUMENT_ERROR",
                "CHASSISD_BLOWERS_SPEED",
                "CHASSISD_BLOWERS_SPEED_FULL",
                "CHASSISD_BLOWERS_SPEED_MEDIUM",
                "CHASSISD_BUS_DEVICE_OPEN_FAILURE",
                "CHASSISD_CB_CLOCK_CHECKSUM",
                "CHASSISD_CB_MASTER_BP_IGNORED",
                "CHASSISD_CB_READ",
                "CHASSISD_CB_RE_ONLINE_BP_IGNORED",
                "CHASSISD_CFEB_POWER_FAILURE",
                "CHASSISD_CLEAR_CONFIG_ERROR",
                "CHASSISD_CLOCK_FAILURE",
                "CHASSISD_CLOCK_NOTICE",
                "CHASSISD_CLOCK_RESET_FAIL",
                "CHASSISD_CMB_READBACK_ERROR",
                "CHASSISD_COMMAND_ACK_ERROR",
                "CHASSISD_COMMAND_ACK_SFM_ERROR",
                "CHASSISD_CONCAT_MODE_ERROR",
                "CHASSISD_CONFIG_ACCESS_ERROR",
                "CHASSISD_CONFIG_CHANGE_IFDEV_DEL",
                "CHASSISD_CONFIG_INIT_ERROR",
                "CHASSISD_CONFIG_WARNING",
                "CHASSISD_DEVICE_OPEN_ERROR",
                "CHASSISD_EXEC_ERROR",
                "CHASSISD_EXISTS",
                "CHASSISD_EXISTS_TERM_OTHER",
                "CHASSISD_FAN_FAILURE",
                "CHASSISD_FASIC_CONFIG_COMPLETE",
                "CHASSISD_FASIC_FTOKEN_ERROR",
                "CHASSISD_FASIC_FTOKEN_INIT_ERROR",
                "CHASSISD_FASIC_HSL_CONFIG_ERROR",
                "CHASSISD_FASIC_HSL_LINK_ERROR",
                "CHASSISD_FASIC_INIT_ERROR",
                "CHASSISD_FASIC_INPUT_DROP",
                "CHASSISD_FASIC_OUTPUT_DROP",
                "CHASSISD_FASIC_PIO_READ_ERROR",
                "CHASSISD_FASIC_PIO_WRITE_ERROR",
                "CHASSISD_FASIC_PLL_ERROR",
                "CHASSISD_FASIC_RESET_ERROR",
                "CHASSISD_FASIC_SRAM_ERROR",
                "CHASSISD_FASIC_VERSION_ERROR",
                "CHASSISD_FCHIP_CONFIG_COMPLETE",
                "CHASSISD_FCHIP_CONFIG_MD_ERROR",
                "CHASSISD_FCHIP_CONFIG_RATE_ERROR",
                "CHASSISD_FCHIP_CONFIG_READ_ERROR",
                "CHASSISD_FCHIP_FTOKEN_ERROR",
                "CHASSISD_FCHIP_FTOKEN_INIT_ERROR",
                "CHASSISD_FCHIP_HSR_ERROR",
                "CHASSISD_FCHIP_HSR_INIT_ERROR",
                "CHASSISD_FCHIP_HSR_INIT_LINK_ERR",
                "CHASSISD_FCHIP_HSR_RESET_ERROR",
                "CHASSISD_FCHIP_HST_ERROR",
                "CHASSISD_FCHIP_HST_INIT_ERROR",
                "CHASSISD_FCHIP_HST_INIT_LINK_ERR",
                "CHASSISD_FCHIP_HST_RESET_ERROR",
                "CHASSISD_FCHIP_INIT_ERROR",
                "CHASSISD_FCHIP_LINK_ERROR",
                "CHASSISD_FCHIP_MONITOR_ERROR",
                "CHASSISD_FCHIP_PIO_READ_ERROR",
                "CHASSISD_FCHIP_PIO_WRITE_ERROR",
                "CHASSISD_FCHIP_POLL_ERROR",
                "CHASSISD_FCHIP_RATE_ERROR",
                "CHASSISD_FCHIP_SIB_NOT_STARTED",
                "CHASSISD_FCHIP_VERSION_ERROR",
                "CHASSISD_FEB_REVERSION",
                "CHASSISD_FEB_SWITCHOVER",
                "CHASSISD_FHSR_READ_REG_ERROR",
                "CHASSISD_FHSR_WRITE_REG_ERROR",
                "CHASSISD_FHST_READ_REG_ERROR",
                "CHASSISD_FHST_WRITE_REG_ERROR",
                "CHASSISD_FILE_OPEN",
                "CHASSISD_FILE_STAT",
                "CHASSISD_FM_ACTION_FPC_OFFLINE",
                "CHASSISD_FM_ACTION_FPC_ONLINE",
                "CHASSISD_FM_ACTION_FPC_POWER_OFF",
                "CHASSISD_FM_ACTION_FPC_RESTART",
                "CHASSISD_FM_ACTION_PLANE_OFFLINE",
                "CHASSISD_FM_ACTION_PLANE_ONLINE",
                "CHASSISD_FM_BAD_STATE",
                "CHASSISD_FM_DETECT_PLANES_DOWN",
                "CHASSISD_FM_DETECT_UNREACHABLE",
                "CHASSISD_FM_ERROR",
                "CHASSISD_FM_ERROR_CLOS_F13_HSR",
                "CHASSISD_FM_ERROR_CLOS_F13_HST",
                "CHASSISD_FM_ERROR_CLOS_F2_HSR",
                "CHASSISD_FM_ERROR_CLOS_F2_HST",
                "CHASSISD_FM_ERROR_F13_FB_HSR_TXP",
                "CHASSISD_FM_ERROR_F13_FB_RX_VC",
                "CHASSISD_FM_ERROR_F13_FB_TXP",
                "CHASSISD_FM_ERROR_F13_FB_TX_VC",
                "CHASSISD_FM_ERROR_F13_VC_PWR",
                "CHASSISD_FM_ERROR_SIB_L_FB_HSR",
                "CHASSISD_FM_ERROR_SIB_L_FB_RX_VC",
                "CHASSISD_FM_ERROR_SIB_L_FB_SMF",
                "CHASSISD_FM_ERROR_SIB_L_FB_TXP",
                "CHASSISD_FM_ERROR_SIB_L_FB_TX_VC",
                "CHASSISD_FM_ERROR_SIB_L_HSR_PFE",
                "CHASSISD_FM_ERROR_SIB_L_HSR_TXP",
                "CHASSISD_FM_ERROR_SIB_L_MISMATCH",
                "CHASSISD_FM_ERROR_SIB_L_VC_PWR",
                "CHASSISD_FM_ERROR_SIB_S_FB_HSR",
                "CHASSISD_FM_ERROR_SIB_S_FB_SMF",
                "CHASSISD_FM_FABRIC_DEGRADED",
                "CHASSISD_FM_MEMORY_ERROR",
                "CHASSISD_FM_SIB_ERROR",
                "CHASSISD_FM_SIB_FPC_TYPE_ERROR",
                "CHASSISD_FPC_NOT_FOUND",
                "CHASSISD_FPC_PIC_DETECT_TIMEOUT",
                "CHASSISD_FPC_TYPE_SIB_TYPE_ERROR",
                "CHASSISD_FRU_ALREADY_OFFLINE",
                "CHASSISD_FRU_ALREADY_ONLINE",
                "CHASSISD_FRU_EVENT",
                "CHASSISD_FRU_FIRE_TEMP_CONDITION",
                "CHASSISD_FRU_HIGH_TEMP_CONDITION",
                "CHASSISD_FRU_INVALID_SLOT",
                "CHASSISD_FRU_IO_ERROR",
                "CHASSISD_FRU_IO_OFFSET_ERROR",
                "CHASSISD_FRU_IPC_WRITE_ERROR",
                "CHASSISD_FRU_OFFLINE_FAILED",
                "CHASSISD_FRU_OFFLINE_NOTICE",
                "CHASSISD_FRU_OFFLINE_TIMEOUT",
                "CHASSISD_FRU_ONLINE_TIMEOUT",
                "CHASSISD_FRU_OVER_TEMP_CONDITION",
                "CHASSISD_FRU_STEP_ERROR",
                "CHASSISD_FRU_UNRESPONSIVE",
                "CHASSISD_FRU_UNRESPONSIVE_RETRY",
                "CHASSISD_FRU_UNSUPPORTED",
                "CHASSISD_FRU_VERSION_MISMATCH",
                "CHASSISD_GASIC_ID_ERROR",
                "CHASSISD_GBUS_NOT_READY",
                "CHASSISD_GBUS_READBACK_ERROR",
                "CHASSISD_GBUS_RESET_EVENT",
                "CHASSISD_GBUS_SANITY_ERROR",
                "CHASSISD_GENERIC_ERROR",
                "CHASSISD_GENERIC_WARNING",
                "CHASSISD_GETTIMEOFDAY",
                "CHASSISD_GRES_UNSUPP_PIC",
                "CHASSISD_HIGH_TEMP_CONDITION",
                "CHASSISD_HOST_TEMP_READ",
                "CHASSISD_HSR_CONFIG_READ_ERROR",
                "CHASSISD_HSR_CONFIG_WRITE_ERROR",
                "CHASSISD_HSR_ELEMENTS_ERROR",
                "CHASSISD_HSR_FIFO_ERROR",
                "CHASSISD_I2CS_READBACK_ERROR",
                "CHASSISD_I2C_BAD_IDEEPROM_FORMAT",
                "CHASSISD_I2C_FIC_PRESENCE_READ",
                "CHASSISD_I2C_GENERIC_ERROR",
                "CHASSISD_I2C_INVALID_ASSEMBLY_ID",
                "CHASSISD_I2C_IOCTL_FAILURE",
                "CHASSISD_I2C_IO_FAILURE",
                "CHASSISD_I2C_MIDPLANE_CORRUPT",
                "CHASSISD_I2C_RANGE_ERROR",
                "CHASSISD_I2C_READ_ERROR",
                "CHASSISD_I2C_WRITE_ERROR",
                "CHASSISD_IDEEPROM_READ_ERROR",
                "CHASSISD_IFDEV_CREATE_FAILURE",
                "CHASSISD_IFDEV_CREATE_NOTICE",
                "CHASSISD_IFDEV_DETACH_ALL_PSEUDO",
                "CHASSISD_IFDEV_DETACH_FPC",
                "CHASSISD_IFDEV_DETACH_PIC",
                "CHASSISD_IFDEV_DETACH_PSEUDO",
                "CHASSISD_IFDEV_DETACH_TLV_ERROR",
                "CHASSISD_IFDEV_GETBYNAME_NOTICE",
                "CHASSISD_IFDEV_GET_BY_INDEX_FAIL",
                "CHASSISD_IFDEV_GET_BY_NAME_FAIL",
                "CHASSISD_IFDEV_NO_MEMORY",
                "CHASSISD_IFDEV_RETRY_NOTICE",
                "CHASSISD_IFDEV_RTSLIB_FAILURE",
                "CHASSISD_IOCTL_FAILURE",
                "CHASSISD_IPC_ANNOUNCE_TIMEOUT",
                "CHASSISD_IPC_CONNECTION_DROPPED",
                "CHASSISD_IPC_DAEMON_WRITE_ERROR",
                "CHASSISD_IPC_ERROR",
                "CHASSISD_IPC_FLUSH_ERROR",
                "CHASSISD_IPC_MSG_DROPPED",
                "CHASSISD_IPC_MSG_ERROR",
                "CHASSISD_IPC_MSG_FRU_NOT_FOUND",
                "CHASSISD_IPC_MSG_QFULL_ERROR",
                "CHASSISD_IPC_MSG_UNHANDLED",
                "CHASSISD_IPC_UNEXPECTED_MSG",
                "CHASSISD_IPC_UNEXPECTED_RECV",
                "CHASSISD_IPC_WRITE_ERROR",
                "CHASSISD_IPC_WRITE_ERR_NO_PIPE",
                "CHASSISD_IPC_WRITE_ERR_NULL_ARGS",
                "CHASSISD_ISSU_BLOB_ERROR",
                "CHASSISD_ISSU_DAEMON_ERROR",
                "CHASSISD_ISSU_ERROR",
                "CHASSISD_ISSU_FRU_ERROR",
                "CHASSISD_ISSU_FRU_IPC_ERROR",
                "CHASSISD_JTREE_ERROR",
                "CHASSISD_LCC_RELEASE_MASTERSHIP",
                "CHASSISD_LOST_MASTERSHIP",
                "CHASSISD_MAC_ADDRESS_AE_ERROR",
                "CHASSISD_MAC_ADDRESS_CBP_ERROR",
                "CHASSISD_MAC_ADDRESS_ERROR",
                "CHASSISD_MAC_ADDRESS_FABRIC_ERR",
                "CHASSISD_MAC_ADDRESS_IRB_ERROR",
                "CHASSISD_MAC_ADDRESS_PIP_ERROR",
                "CHASSISD_MAC_ADDRESS_PLT_ERROR",
                "CHASSISD_MAC_ADDRESS_SWFAB_ERR",
                "CHASSISD_MAC_ADDRESS_VLAN_ERROR",
                "CHASSISD_MAC_DEFAULT",
                "CHASSISD_MALLOC_FAILURE",
                "CHASSISD_MASTER_CG_REMOVED",
                "CHASSISD_MASTER_PCG_REMOVED",
                "CHASSISD_MASTER_SCG_REMOVED",
                "CHASSISD_MBUS_ERROR",
                "CHASSISD_MCHASSIS_SWITCH_WARNING",
                "CHASSISD_MCS_INTR_ERROR",
                "CHASSISD_MGR_CONNECT",
                "CHASSISD_MIC_OFFLINE_NOTICE",
                "CHASSISD_MULTILINK_BUNDLES_ERROR",
                "CHASSISD_NO_CGS",
                "CHASSISD_NO_PCGS",
                "CHASSISD_NO_SCGS",
                "CHASSISD_OFFLINE_NOTICE",
                "CHASSISD_OID_GEN_FAILED",
                "CHASSISD_OVER_TEMP_CONDITION",
                "CHASSISD_OVER_TEMP_SHUTDOWN_TIME",
                "CHASSISD_PARSE_COMPLETE",
                "CHASSISD_PCI_ERROR",
                "CHASSISD_PDU_BREAKER_TRIP",
                "CHASSISD_PDU_NOT_OK",
                "CHASSISD_PEER_UNCONNECTED",
                "CHASSISD_PEM_BREAKER_TRIP",
                "CHASSISD_PEM_IMPROPER",
                "CHASSISD_PEM_INPUT_BAD",
                "CHASSISD_PEM_NOT_SUFFICIENT",
                "CHASSISD_PEM_OVERLOAD",
                "CHASSISD_PEM_TEMPERATURE",
                "CHASSISD_PEM_VOLTAGE",
                "CHASSISD_PIC_CMD_GIVEUP",
                "CHASSISD_PIC_CMD_TIMEOUT",
                "CHASSISD_PIC_CONFIG_CONFLICT",
                "CHASSISD_PIC_CONFIG_ERROR",
                "CHASSISD_PIC_HWERROR",
                "CHASSISD_PIC_OFFLINE_NOTICE",
                "CHASSISD_PIC_OID_GEN_FAILED",
                "CHASSISD_PIC_OID_UNKNOWN",
                "CHASSISD_PIC_PORT_ERROR",
                "CHASSISD_PIC_RESET_ON_SWITCHOVER",
                "CHASSISD_PIC_SPEED_INVALID",
                "CHASSISD_PIC_VERSION_ERROR",
                "CHASSISD_PIDFILE_OPEN",
                "CHASSISD_PIPE_WRITE_ERROR",
                "CHASSISD_POWER_CHECK",
                "CHASSISD_POWER_EVENT",
                "CHASSISD_POWER_ON_CHECK_FAILURE",
                "CHASSISD_POWER_RATINGS_EXCEEDED",
                "CHASSISD_PSD_RELEASE_MASTERSHIP",
                "CHASSISD_PSM_NOT_OK",
                "CHASSISD_PSU_ERROR",
                "CHASSISD_PSU_FAN_FAIL",
                "CHASSISD_PSU_INPUT_BAD",
                "CHASSISD_PSU_OVERLOAD",
                "CHASSISD_PSU_TEMPERATURE",
                "CHASSISD_PSU_VOLTAGE",
                "CHASSISD_RANGE_CHECK",
                "CHASSISD_RECONNECT_SUCCESSFUL",
                "CHASSISD_RELEASE_MASTERSHIP",
                "CHASSISD_RE_CONSOLE_FE_STORM",
                "CHASSISD_RE_INIT_INVALID_RE_SLOT",
                "CHASSISD_RE_OVER_TEMP_CONDITION",
                "CHASSISD_RE_OVER_TEMP_SHUTDOWN",
                "CHASSISD_RE_OVER_TEMP_WARNING",
                "CHASSISD_RE_WARM_TEMP_CONDITION",
                "CHASSISD_ROOT_MOUNT_ERROR",
                "CHASSISD_RTS_SEQ_ERROR",
                "CHASSISD_SBOARD_VERSION_MISMATCH",
                "CHASSISD_SENSOR_RANGE_NOTICE",
                "CHASSISD_SERIAL_ID",
                "CHASSISD_SFM_MODE_ERROR",
                "CHASSISD_SFM_NOT_ONLINE",
                "CHASSISD_SHUTDOWN_NOTICE",
                "CHASSISD_SIB_INVALID_SLOT",
                "CHASSISD_SIGPIPE",
                "CHASSISD_SMB_ERROR",
                "CHASSISD_SMB_INVALID_PS",
                "CHASSISD_SMB_IOCTL_FAILURE",
                "CHASSISD_SMB_READ_FAILURE",
                "CHASSISD_SNMP_TRAP1",
                "CHASSISD_SNMP_TRAP10",
                "CHASSISD_SNMP_TRAP6" ,
                "CHASSISD_SNMP_TRAP7",
                "CHASSISD_SPI_IOCTL_FAILURE",
                "CHASSISD_SPMB_RESTART",
                "CHASSISD_SPMB_RESTART_TIMEOUT",
                "CHASSISD_SSB_FAILOVERS",
                "CHASSISD_STANDALONE_FPC_NOTICE",
                "CHASSISD_SYSCTL_ERROR",
                "CHASSISD_TEMP_HOT_NOTICE",
                "CHASSISD_TEMP_SENSOR_FAILURE",
                "CHASSISD_TERM_SIGNAL",
                "CHASSISD_TIMER_CLR_ERR",
                "CHASSISD_TIMER_ERR",
                "CHASSISD_TIMER_VAL_ERR",
                "CHASSISD_UNEXPECTED_EXIT",
                "CHASSISD_UNEXPECTED_VALUE",
                "CHASSISD_UNSUPPORTED_FPC",
                "CHASSISD_UNSUPPORTED_MODEL",
                "CHASSISD_UNSUPPORTED_PIC",
                "CHASSISD_UNSUPPORTED_PIC_MODE",
                "CHASSISD_UNSUPPORTED_SIB",
                "CHASSISD_VCHASSIS_CONVERT_ERROR",
                "CHASSISD_VCHASSIS_LICENSE_ERROR",
                "CHASSISD_VERSION_MISMATCH",
                "CHASSISD_VOLTAGE_READ_FAILED",
                "CHASSISD_VOLTAGE_SENSOR_INIT",
                "CHASSISD_VSERIES_LICENSE_ERROR",
                "CHASSISD_ZONE_BLOWERS_SPEED",
                "CHASSISD_ZONE_BLOWERS_SPEED_FULL"
            };
            return names;
        }
};

class CHASSISMGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "CHASSISM" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "CHASSISM_SYSTEM"
            };
            return names;
        }
};

 class COSDGroup : public IJunosFacilityGroup
 {
     public:
         string GetGroupName()
         {
           return string( "COSD" );
         }

         vector<string>& GetFacilityNames()
         {
              static vector<string> names =
              {
                  "COSD_AGGR_CONFIG_INVALID",
                  "COSD_CHASSIS_SCHED_MAP_INVALID",
                  "COSD_CLASSIFIER_NO_SUPPORT_LSI",
                  "COSD_CLASS_8021P_UNSUPPORTED",
                  "COSD_CONF_OPEN_FAILURE",
                  "COSD_DB_OPEN_FAILED",
                  "COSD_EXACT_RATE_UNSUPP_INTERFACE",
                  "COSD_EXACT_RATE_UNSUPP_SESSION",
                  "COSD_FRAGMENTATION_MAP_CONFLICT",
                  "COSD_HIGH_PRIO_QUEUES_INTERFACE",
                  "COSD_HIGH_PRIO_QUEUES_SESSION",
                  "COSD_IFD_OUTPUT_SHAPING_RATE_ERR",
                  "COSD_IFD_SHAPER_ERR",
                  "COSD_INTERFACE_NO_MEDIA",
                  "COSD_L2TP_COS_NOT_CONFIGURED",
                  "COSD_L2TP_COS_NOT_SUPPORTED",
                  "COSD_L2TP_SHAPING_NOT_CONFIGURED",
                  "COSD_LARGE_DELAY_BUFFER_INVALID",
                  "COSD_MALLOC_FAILED",
                  "COSD_MPLS_DSCP_CLASS_NO_SUPPORT",
                  "COSD_MULTILINK_CLASS_CONFLICT",
                  "COSD_NULL_INPUT_ARGUMENT",
                  "COSD_OUT_OF_DEDICATED_QUEUES",
                  "COSD_RATE_LIMIT_INVALID",
                  "COSD_RATE_LIMIT_NOT_SUPPORTED",
                  "COSD_REWRITE_RULE_LIMIT_EXCEEDED",
                  "COSD_RL_IFL_NEEDS_SHAPING",
                  "COSD_SCHEDULER_MAP_CONFLICT",
                  "COSD_SCHED_AVG_CONST_UNSUPPORTED",
                  "COSD_SCHED_MAP_GROUP_CONFLICT",
                  "COSD_SHAPER_GROUP_CONFLICT",
                  "COSD_STREAM_IFD_CREATE_FAILURE",
                  "COSD_TIMER_ERROR",
                  "COSD_TRICOLOR_ALWAYS_ON",
                  "COSD_TRICOLOR_NOT_SUPPORTED",
                  "COSD_TX_QUEUE_RATES_TOO_HIGH",
                  "COSD_UNKNOWN_CLASSIFIER",
                  "COSD_UNKNOWN_REWRITE",
                  "COSD_UNKNOWN_TRANSLATION_TABLE"
              };
              return names;
         }
 };

class DCBXGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "DCBX" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "DCBX_PFC_DISABLED"
                "DCBX_PFC_ENABLED",
                "DCBX_VERSION"
            };
            return names;
        }
};

class DCDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "DCD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
             {
                "DCD_AE_CONFIG_WARNING",
                "DCD_GRE_CONFIG_INVALID",
                "DCD_MALLOC_FAILED_INIT",
                "DCD_PARSE_CFG_WARNING",
                "DCD_PARSE_EMERGENCY",
                "DCD_PARSE_ERROR_CLOCK",
                "DCD_PARSE_ERROR_HIER_SCHEDULER",
                "DCD_PARSE_ERROR_IFLSET",
                "DCD_PARSE_ERROR_MAX_HIER_LEVELS",
                "DCD_PARSE_ERROR_SCHEDULER",
                "DCD_PARSE_ERROR_SCHEDULER_LIMIT",
                "DCD_PARSE_ERROR_VLAN_TAGGING",
                "DCD_PARSE_MINI_EMERGENCY",
                "DCD_PARSE_STATE_EMERGENCY",
                "DCD_PARSE_WARN_INCOMPATIBLE_CFG"
             };
            return names;
        }
};

class DDOSGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "DDOS" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "DDOS_PROTOCOL_VIOLATION_CLEAR",
                "DDOS_PROTOCOL_VIOLATION_SET",
                "DDOS_RTSOCK_FAILURE"
            };
            return names;
        }
};

class DFCDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "DFCD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "DFCD_FTAP_PIC_UNSUPPORTED",
                "DFCD_GENCFG_MALLOC_FAILED",
                "DFCD_GENCFG_WRITE_FAILED",
                "DFCD_LINH_MALLOC_FAILED",
                "DFCD_LI_NEXT_HOP_ADD_FAILED",
                "DFCD_NEXT_HOP_ADD_FAILED",
                "DFCD_NEXT_HOP_DELETE_FAILED",
                "DFCD_SAMPLE_CLASS_ADD_FAILED",
                "DFCD_SAMPLE_CLASS_DELETE_FAILED"
            };
            return names;
        }
};

class DFWDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "DFWD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "DFWD_MALLOC_FAILED_INIT",
                "DFWD_PARSE_FILTER_EMERGENCY",
                "DFWD_PARSE_STATE_EMERGENCY",
                "DFWD_POLICER_LIMIT_EXCEEDED"
            };
            return names;
        }
};

class DHCPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "DHCPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "DHCPD_BIND_FAILURE",
                "DHCPD_DEGRADED_MODE",
                "DHCPD_MEMORY_ALLOCATION_FAILURE",
                "DHCPD_OVERLAY_CONFIG_FAILURE",
                "DHCPD_OVERLAY_PARSE_FAILURE",
                "DHCPD_RECVMSG_FAILURE",
                "DHCPD_RTSOCK_FAILURE",
                "DHCPD_SENDMSG_FAILURE",
                "DHCPD_SENDMSG_NOINT_FAILURE",
                "DHCPD_SETSOCKOPT_FAILURE",
                "DHCPD_SOCKET_FAILURE"
            };
            return names;
        }
};

class DOT1XDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "DOT1XD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "DOT1XD_AUTH_SESSION_DELETED",
                "DOT1XD_RCVD_EAPLOGOF_ATHNTCTNG",
                "DOT1XD_RCVD_EAPLOGOF_ATHNTICTD",
                "DOT1XD_RCVD_EAPLOGOF_CONNECTNG",
                "DOT1XD_USR_ACCESS_DENIED",
                "DOT1XD_USR_ATHNTICTD_GST_VLAN",
                "DOT1XD_USR_AUTHENTICATED",
                "DOT1XD_USR_OFF_DUE_TO_MAC_AGNG",
                "DOT1XD_USR_ON_SRVR_FAIL_VLAN",
                "DOT1XD_USR_ON_SRVR_REJECT_VLAN",
                "DOT1XD_USR_SESSION_DISCONNECTED",
                "DOT1XD_USR_SESSION_HELD",
                "DOT1XD_USR_UNATHNTCTD_CLI_CLRD"
            };
            return names;
        }
};

class DYNAMICGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "DYNAMIC" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "DYNAMIC_VPN_AUTH_CONNECT_FAIL",
                "DYNAMIC_VPN_AUTH_FAIL",
                "DYNAMIC_VPN_AUTH_INVALID",
                "DYNAMIC_VPN_AUTH_MUL_CONN",
                "DYNAMIC_VPN_AUTH_NO_CONFIG",
                "DYNAMIC_VPN_AUTH_NO_LICENSE",
                "DYNAMIC_VPN_AUTH_OK",
                "DYNAMIC_VPN_CLIENT_CONFIG_WRITE",
                "DYNAMIC_VPN_CONN_DEL_NOTIFY",
                "DYNAMIC_VPN_CONN_DEL_REQUEST",
                "DYNAMIC_VPN_CONN_EST_NOTIFY",
                "DYNAMIC_VPN_INIT_SUCCESSFUL",
                "DYNAMIC_VPN_LICENSE_ASSIGNED",
                "DYNAMIC_VPN_LICENSE_CHECK_FAILED",
                "DYNAMIC_VPN_LICENSE_CHECK_OK",
                "DYNAMIC_VPN_LICENSE_EXHAUSTED",
                "DYNAMIC_VPN_LICENSE_FREED",
                "DYNAMIC_VPN_LICENSE_FREE_FAILED",
                "DYNAMIC_VPN_LICENSE_FREE_OK",
                "DYNAMIC_VPN_LICENSE_GET_FAILED",
                "DYNAMIC_VPN_LICENSE_GET_OK",
                "DYNAMIC_VPN_LICENSE_INSTALLED",
                "DYNAMIC_VPN_LICENSE_REQUIRED",
                "DYNAMIC_VPN_LICENSE_UNINSTALLED"
            };
            return names;
        }
};

class ESWDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "ESWD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "ESWD_BPDU_BLOCK_ERROR_DISABLED",
                "ESWD_BPDU_BLOCK_ERROR_ENABLED",
                "ESWD_DAI_FAILED",
                "ESWD_DHCP_UNTRUSTED",
                "ESWD_INVALID_MAC_ADDRESS",
                "ESWD_LEARNT_FDB_MEMORY_ERROR",
                "ESWD_MAC_LIMIT_ALERT",
                "ESWD_MAC_LIMIT_BLOCK",
                "ESWD_MAC_LIMIT_DROP",
                "ESWD_MAC_LIMIT_EXCEEDED",
                "ESWD_MAC_MOVE_LIMIT_BLOCK",
                "ESWD_MAC_MOVE_LIMIT_DROP",
                "ESWD_MAC_MOVE_LIMIT_EXCEEDED",
                "ESWD_MIRROR_ERROR",
                "ESWD_MIRROR_VERSION_MISMATCH",
                "ESWD_MODULE_SHUTDOWN_FAILURE",
                "ESWD_OUT_OF_LOW_MEMORY",
                "ESWD_PPM_READ_ERROR",
                "ESWD_PPM_WRITE_ERROR",
                "ESWD_STATIC_FDB_MEMORY_WARNING",
                "ESWD_STP_BASE_MAC_ERROR",
                "ESWD_STP_LOOP_PROTECT_CLEARED",
                "ESWD_STP_LOOP_PROTECT_IN_EFFECT",
                "ESWD_STP_ROOT_PROTECT_CLEARED",
                "ESWD_STP_ROOT_PROTECT_IN_EFFECT",
                "ESWD_STP_STATE_CHANGE_INFO",
                "ESWD_ST_CTL_BW_INFO",
                "ESWD_ST_CTL_ERROR_DISABLED",
                "ESWD_ST_CTL_ERROR_ENABLED",
                "ESWD_ST_CTL_ERROR_IN_EFFECT",
                "ESWD_ST_CTL_INFO",
                "ESWD_VLAN_MAC_LIMIT_EXCEEDED",
            };
            return names;
        }
};

class EVENTDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "EVENTD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "EVENTD_ACK_FAILED",
                "EVENTD_ALARM_CLEAR",
                "EVENTD_ALARM_FILE",
                "EVENTD_AUDIT_DISABLED",
                "EVENTD_AUDIT_ENABLED",
                "EVENTD_AUDIT_SHOW",
                "EVENTD_COMMAND_SUBSTITUTE_ERROR",
                "EVENTD_CONFIG_CHANGE_FAILED",
                "EVENTD_CONFIG_CHANGE_SUCCESS",
                "EVENTD_ESCRIPT_EXECUTION",
                "EVENTD_ESCRIPT_NOT_CONFIGURED",
                "EVENTD_EVENT_SEND_FAILED",
                "EVENTD_FORK_ERR",
                "EVENTD_PIPE_CREATION_FAILED",
                "EVENTD_POLICY_ACTION_FAILED",
                "EVENTD_POLICY_LIMIT_EXCEEDED",
                "EVENTD_POLICY_UPLOAD_FAILED",
                "EVENTD_POPEN_FAIL",
                "EVENTD_READ_ERROR",
                "EVENTD_REGEXP_INVALID",
                "EVENTD_REG_VERSION_MISMATCH",
                "EVENTD_ROTATE_COMMAND_FAILED",
                "EVENTD_ROTATE_FORK_EXCEEDED",
                "EVENTD_ROTATE_FORK_FAILED",
                "EVENTD_SCRIPT_CHECKSUM_MISMATCH",
                "EVENTD_SECURITY_LOG_CLEAR",
                "EVENTD_SET_PROCESS_PRIV_FAILED",
                "EVENTD_SET_TIMER_FAILED",
                "EVENTD_SYSLOG_FWD_FAILED",
                "EVENTD_TEST_ALARM",
                "EVENTD_TRANSFER_COMMAND_FAILED",
                "EVENTD_TRANSFER_FORK_EXCEEDED",
                "EVENTD_TRANSFER_FORK_FAILED",
                "EVENTD_VERSION_MISMATCH",
                "EVENTD_XML_FILENAME_INVALID"
            };
            return names;
        }
};

class FABOAMDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "FABOAMD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FABOAMD_DEBUGGING",
                "FABOAMD_TASK_SOCK_ERR"
            };
            return names;
        }
};

class FCGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "FC" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FC_FABRIC_CREATED",
                "FC_FABRIC_DELETED",
                "FC_FABRIC_WWN_ASSIGNED",
                "FC_FABRIC_WWN_CLEARED",
                "FC_FLOGI_VN_PORT_LOGIN_FAILED",
                "FC_LOGICAL_INTERFACE_CREATED",
                "FC_LOGICAL_INTERFACE_DELETED",
                "FC_LOGICAL_INTERFACE_ISOLATED",
                "FC_PROXY_NP_PORT_LB_ADDED",
                "FC_PROXY_NP_PORT_LB_REMOVED",
                "FC_PROXY_NP_PORT_LOGIN_ABORTED",
                "FC_PROXY_NP_PORT_LOGIN_FAILED",
                "FC_PROXY_NP_PORT_LOGOUT",
                "FC_PROXY_NP_PORT_NPIV_FAILED",
                "FC_PROXY_NP_PORT_OFFLINE",
                "FC_PROXY_NP_PORT_ONLINE",
                "FC_PROXY_VN_PORT_LOGIN_ABORTED",
                "FC_PROXY_VN_PORT_LOGIN_FAILED"
            };
            return names;
        }
};

class FCOEGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "FCOE" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FCOE_LOGICAL_INTERFACE_CREATED",
                "FCOE_LOGICAL_INTERFACE_DELETED",
                "FCOE_LOGICAL_INTERFACE_ISOLATED"
            };
            return names;
        }
};

class FIPGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "FIP" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FIP_ENODE_CLEARED",
                "FIP_ENODE_FKA_TIMER_EXPIRED",
                "FIP_ENODE_LEARNED",
                "FIP_MAX_FCOE_FILTERS_REACHED",
                "FIP_MAX_SESSIONS_REACHED",
                "FIP_PROTOCOL_STARTED",
                "FIP_PROTOCOL_STOPPED",
                "FIP_VN_PORT_FKA_TIMER_EXPIRED",
                "FIP_VN_PORT_LOGIN_FAILED",
                "FIP_VN_PORT_SESSION_CLEARED",
                "FIP_VN_PORT_SESSION_CREATED"
            };
            return names;
        }
};

class FIPSGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "FIPS" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FIPS_KNOWN_ANSWER_TEST"
            };
            return names;
        }
};

class FLOWGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "FLOW" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FLOW_APP_POLICY_VIOLATION",
                "FLOW_DSTIP_POLICY_VIOLATION",
                "FLOW_HIGH_WATERMARK_TRIGGERED",
                "FLOW_HIGH_WATERMARK_TRIGGERED_LS",
                "FLOW_IP_ACTION",
                "FLOW_IP_ACTION_LS",
                "FLOW_LOW_WATERMARK_TRIGGERED",
                "FLOW_LOW_WATERMARK_TRIGGERED_LS",
                "FLOW_POLICY_VIOLATION",
                "FLOW_REASSEMBLE_FAIL",
                "FLOW_REASSEMBLE_SUCCEED",
                "FLOW_SRCIP_POLICY_VIOLATION"
            };
            return names;
        }
};

class FPCLOGINGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "FPCLOGIN" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FPCLOGIN_ADDRESS_GET_FAILED",
                "FPCLOGIN_IPC_RECEIVE_FAILED",
                "FPCLOGIN_IPC_SEND_FAILED",
                "FPCLOGIN_LOGIN_FAILED",
                "FPCLOGIN_MESSAGE_INVALID",
                "FPCLOGIN_SOCKET_OPERATION_FAILED"
            };
            return names;
        }
};

class FSADGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "FSAD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FSAD_CONFIG_ERROR",
                "FSAD_CONNTIMEDOUT",
                "FSAD_DIR_CREATE",
                "FSAD_DIR_STAT",
                "FSAD_FAILED",
                "FSAD_FILE_FAILED",
                "FSAD_FILE_REMOVE",
                "FSAD_FILE_RENAME",
                "FSAD_FILE_STAT",
                "FSAD_FILE_SYNC",
                "FSAD_FLOWC_IPC_PAYLOAD_SIZE",
                "FSAD_FLOWC_IPC_SUBTYPE",
                "FSAD_FLOWC_IPC_TYPE",
                "FSAD_FLOWC_IPC_VERSION",
                "FSAD_FLOWC_SERVICE_INACTIVE",
                "FSAD_FREE_SPACE_LOG",
                "FSAD_FREE_SPACE_TMP",
                "FSAD_FS_STAT",
                "FSAD_GEN_IPC_PAYLOAD_SIZE",
                "FSAD_GEN_IPC_SUBTYPE",
                "FSAD_GEN_IPC_TYPE",
                "FSAD_GEN_IPC_VERSION",
                "FSAD_GEN_SERVICE_INACTIVE",
                "FSAD_GEN_SERVICE_INIT_FAILED",
                "FSAD_MAXCONN",
                "FSAD_MEMORYALLOC_FAILED",
                "FSAD_NOT_ROOT",
                "FSAD_PARENT_DIRECTORY",
                "FSAD_PATH_IS_DIRECTORY",
                "FSAD_PATH_IS_NOT_DIRECTORY",
                "FSAD_PATH_IS_SPECIAL",
                "FSAD_RECVERROR",
                "FSAD_RENAME",
                "FSAD_TERMINATED_CONNECTION",
                "FSAD_TRACEOPEN_FAILED",
                "FSAD_USAGE"
            };
            return names;
        }
};

class FUDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "FUD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
             {
                "FUD_ARGUMENT_FAILURE",
                "FUD_BAD_SERVER_ADDR_FAILURE",
                "FUD_BIND_FAILURE",
                "FUD_DAEMON_FAILURE",
                "FUD_MEMORY_ALLOCATION_FAILURE",
                "FUD_PERMISSION_FAILURE",
                "FUD_PIDLOCK_FAILURE",
                "FUD_PIDUPDATE_FAILURE",
                "FUD_RECVMSG_FAILURE",
                "FUD_RTSOCK_WRITE_FAILURE",
                "FUD_SENDMSG_FAILURE",
                "FUD_SENDMSG_NOINT_FAILURE",
                "FUD_SETSOCKOPT_FAILURE",
                "FUD_SOCKET_FAILURE"
             };
            return names;
        }
};

class FWAUTHGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "FWAUTH" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "FWAUTH_FTP_LONG_PASSWORD",
                "FWAUTH_FTP_LONG_PASSWORD_LS",
                "FWAUTH_FTP_LONG_USERNAME",
                "FWAUTH_FTP_LONG_USERNAME_LS",
                "FWAUTH_FTP_USER_AUTH_ACCEPTED",
                "FWAUTH_FTP_USER_AUTH_ACCEPTED_LS",
                "FWAUTH_FTP_USER_AUTH_FAIL",
                "FWAUTH_FTP_USER_AUTH_FAIL_LS",
                "FWAUTH_HTTP_USER_AUTH_ACCEPTED",
                "FWAUTH_HTTP_USER_AUTH_FAIL",
                "FWAUTH_HTTP_USER_AUTH_FAIL_LS",
                "FWAUTH_HTTP_USER_AUTH_OK_LS",
                "FWAUTH_TELNET_LONG_PASSWORD",
                "FWAUTH_TELNET_LONG_PASSWORD_LS",
                "FWAUTH_TELNET_LONG_USERNAME",
                "FWAUTH_TELNET_LONG_USERNAME_LS",
                "FWAUTH_TELNET_USER_AUTH_ACCEPTED",
                "FWAUTH_TELNET_USER_AUTH_FAIL",
                "FWAUTH_TELNET_USER_AUTH_FAIL_LS",
                "FWAUTH_TELNET_USER_AUTH_OK_LS",
                "FWAUTH_WEBAUTH_FAIL",
                "FWAUTH_WEBAUTH_FAIL_LS",
                "FWAUTH_WEBAUTH_SUCCESS",
                "FWAUTH_WEBAUTH_SUCCESS_LS"
            };
            return names;
        }
};

class GPRSDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "GPRSD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "GPRSD_MEMORY_ALLOC_FAILED",
                "GPRSD_RESTART_CCFG_READ_FAILED"
            };
            return names;
        }
};

class HNCACHEDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "HNCACHED" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "HNCACHED_HOST_ADDRESS_CHANGED",
                "HNCACHED_NAME_RESOLUTION_FAILURE"
            };
            return names;
        }
};

class ICCPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "ICCPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "ICCPD_ASSERT_SOFT",
                "ICCPD_OPEN_ERROR",
                "ICCPD_READ_ERROR",
                "ICCPD_WRITE_ERROR"
            };
            return names;
        }
};

class IDPGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "IDP" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "IDP_APPDDOS_APP_ATTACK_EVENT",
                "IDP_APPDDOS_APP_ATTACK_EVENT_LS",
                "IDP_APPDDOS_APP_STATE_EVENT",
                "IDP_APPDDOS_APP_STATE_EVENT_LS",
                "IDP_ATTACK_LOG_EVENT_LS",
                "IDP_COMMIT_COMPLETED",
                "IDP_COMMIT_FAILED",
                "IDP_DAEMON_INIT_FAILED",
                "IDP_IGNORED_IPV6_ADDRESSES",
                "IDP_INTERNAL_ERROR",
                "IDP_POLICY_COMPILATION_FAILED",
                "IDP_POLICY_LOAD_FAILED",
                "IDP_POLICY_LOAD_SUCCEEDED",
                "IDP_POLICY_UNLOAD_FAILED",
                "IDP_POLICY_UNLOAD_SUCCEEDED",
                "IDP_SCHEDULEDUPDATE_START_FAILED",
                "IDP_SCHEDULED_UPDATE_STARTED",
                "IDP_SECURITY_INSTALL_RESULT",
                "IDP_SESSION_LOG_EVENT",
                "IDP_SESSION_LOG_EVENT_LS",
                "IDP_SIGNATURE_LICENSE_EXPIRED"
            };
            return names;
        }
};

class JADEGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "JADE" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "JADE_ATTRIBUTES_TOO_LONG",
                "JADE_AUTH_FAILURE",
                "JADE_AUTH_SUCCESS",
                "JADE_EXEC_ERROR",
                "JADE_IRI_AUTH_SUCCESS",
                "JADE_PAM_ERROR",
                "JADE_PAM_NO_LOCAL_USER",
                "JADE_SOCKET_ERROR"
            };
            return names;
        }
};

class JCSGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "JCS" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "JCS_BBD_LOAD_FAILURE",
                "JCS_BBD_LOCAL_MISMATCH",
                "JCS_BBD_NOT_FOUND",
                "JCS_BBD_NOT_VALID",
                "JCS_BBD_PARSE_ERROR",
                "JCS_BBD_PEER_MISMATCH",
                "JCS_BBD_SYSTEM_CONFLICT",
                "JCS_EXT_LINK_STATE",
                "JCS_INVALID_BANDWIDTH_ERROR",
                "JCS_KERNEL_RSD_LINK_DOWN",
                "JCS_KERNEL_RSD_LINK_ENABLED",
                "JCS_MM_COMMUNICATION_ERROR",
                "JCS_MM_COMMUNICATION_OK",
                "JCS_PEER_BLADE_STATE",
                "JCS_READ_BANDWIDTH_ERROR",
                "JCS_READ_BBD_ERROR",
                "JCS_RSD_LINK_STATE",
                "JCS_SWITCH_BANDWIDTH_CONFIG",
                "JCS_SWITCH_COMMUNICATION_ERROR",
                "JCS_SWITCH_COMMUNICATION_OK"
            };
            return names;
        }
};

class JDIAMETERDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "JDIAMETERD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "JDIAMETERD_FUNC_HSHAKE_FAIL",
                "JDIAMETERD_FUNC_LOCACCEPT_NFOUND",
                "JDIAMETERD_FUNC_NSCK_LISTEN_FAIL",
                "JDIAMETERD_FUNC_OUT_OF_SYNC",
                "JDIAMETERD_FUNC_PICACCEPT_NFOUND",
                "JDIAMETERD_FUNC_TOO_MANY_BADE2ES",
                "JDIAMETERD_FUNC_USCK_LISTEN_FAIL"
            };
            return names;
        }
};

class JIVEDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "JIVED" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "JIVED_ALREADY_RUNNING",
                "JIVED_EVLIB_FUNC_FAILED",
                "JIVED_INITIATE_CONN_FAILED",
                "JIVED_INIT_FAILED",
                "JIVED_NOT_ROOT",
                "JIVED_PIDFILE_LOCK_FAILED",
                "JIVED_PIDFILE_UPDATE_FAILED",
                "JIVED_SNMP_SEND_TRAP_FAILED"
            };
            return names;
        }
};

class JPTSPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "JPTSPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "JPTSPD_INIT_FAILURE",
                "JPTSPD_OUT_OF_MEMORY",
                "JPTSPD_PIC_CONNECTED",
                "JPTSPD_PIC_DISCONNECTED",
                "JPTSPD_SRC_FAST_SYNC_ABORT",
                "JPTSPD_SRC_FAST_SYNC_DONE",
                "JPTSPD_SRC_FAST_SYNC_START",
                "JPTSPD_SRC_FULL_SYNC_ABORT",
                "JPTSPD_SRC_FULL_SYNC_DONE",
                "JPTSPD_SRC_FULL_SYNC_START"
            };
            return names;
        }
};

class JSRPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "JSRPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "JSRPD_DAEMONIZE_FAILED",
                "JSRPD_DUPLICATE",
                "JSRPD_NODE_STATE_CHANGE",
                "JSRPD_NOT_ROOT",
                "JSRPD_PID_FILE_LOCK",
                "JSRPD_PID_FILE_UPDATE",
                "JSRPD_REDUNDANCY_MODE_CHANGE",
                "JSRPD_REDUNDANCY_MODE_MISMATCH",
                "JSRPD_RG_STATE_CHANGE",
                "JSRPD_SET_CS_MON_FAILURE",
                "JSRPD_SET_HW_MON_FAILURE",
                "JSRPD_SET_INTF_MON_FAILURE",
                "JSRPD_SET_IP_MON_FAILURE",
                "JSRPD_SET_LOOPBACK_MON_FAILURE",
                "JSRPD_SET_MBUF_MON_FAILURE",
                "JSRPD_SET_NEXTHOP_MON_FAILURE",
                "JSRPD_SET_NPC_MON_FAILURE",
                "JSRPD_SET_OTHER_INTF_MON_FAIL",
                "JSRPD_SET_SPU_MON_FAILURE",
                "JSRPD_SOCKET_CREATION_FAILURE",
                "JSRPD_SOCKET_LISTEN_FAILURE",
                "JSRPD_SOCKET_RECV_HB_FAILURE",
                "JSRPD_UNSET_CS_MON_FAILURE",
                "JSRPD_UNSET_HW_MON_FAILURE",
                "JSRPD_UNSET_INTF_MON_FAILURE",
                "JSRPD_UNSET_IP_MON_FAILURE",
                "JSRPD_UNSET_LOOPBACK_MON_FAILURE",
                "JSRPD_UNSET_MBUF_MON_FAILURE",
                "JSRPD_UNSET_NEXTHOP_MON_FAILURE",
                "JSRPD_UNSET_NPC_MON_FAILURE",
                "JSRPD_UNSET_OTHER_INTF_MON_FAIL",
                "JSRPD_UNSET_SPU_MON_FAILURE",
                "JSRPD_USAGE"
            };
            return names;
        }
};

class JTASKGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "JTASK" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "JTASK_ABORT",
                "JTASK_ACTIVE_TERMINATE",
                "JTASK_ASSERT",
                "JTASK_ASSERT_SOFT",
                "JTASK_CFG_CALLBACK_LONGRUNTIME",
                "JTASK_CFG_SCHED_CUMU_LONGRUNTIME",
                "JTASK_EXIT",
                "JTASK_LOCK_FLOCKED",
                "JTASK_LOCK_LOCKED",
                "JTASK_MGMT_TIMEOUT",
                "JTASK_OS_MEMHIGH",
                "JTASK_PARSE_BAD_LR_NAME",
                "JTASK_PARSE_BAD_OPTION",
                "JTASK_PARSE_CMD_ARG",
                "JTASK_PARSE_CMD_DUPLICATE",
                "JTASK_PARSE_CMD_EXTRA",
                "JTASK_PTHREAD_CREATE",
                "JTASK_SCHED_CUMU_LONGRUNTIME",
                "JTASK_SCHED_MODULE_LONGRUNTIME",
                "JTASK_SCHED_TASK_LONGRUNTIME",
                "JTASK_SIGNAL_TERMINATE",
                "JTASK_SNMP_CONN_EINPROGRESS",
                "JTASK_SNMP_CONN_QUIT",
                "JTASK_SNMP_CONN_RETRY",
                "JTASK_SNMP_INVALID_SOCKET",
                "JTASK_SNMP_SOCKOPT_BLOCK",
                "JTASK_SNMP_SOCKOPT_RECVBUF",
                "JTASK_SNMP_SOCKOPT_SENDBUF",
                "JTASK_START",
                "JTASK_SYSTEM",
                "JTASK_TASK_CHILDKILLED",
                "JTASK_TASK_CHILDSTOPPED",
                "JTASK_TASK_DYN_REINIT",
                "JTASK_TASK_FORK",
                "JTASK_TASK_GETWD",
                "JTASK_TASK_MASTERSHIP",
                "JTASK_TASK_NOREINIT",
                "JTASK_TASK_PIDCLOSED",
                "JTASK_TASK_PIDFLOCK",
                "JTASK_TASK_PIDWRITE",
                "JTASK_TASK_REINIT",
                "JTASK_TASK_SIGNALIGNORE"
            };
            return names;
        }
};

class JTRACEGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "JTRACE" );
        }

        vector<string>& GetFacilityNames()
        {
          static vector<string> names =
          {
              "JTRACE_FAILED"
          };
          return names;
        }
};

class KMDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "KMD" );
        }

        vector<string>& GetFacilityNames()
        {
              static vector<string> names =
              {
                  "KMD_CFG_IF_ID_POOL_NOT_FOUND",
                  "KMD_CFG_IF_ID_POOL_NO_ENTRY",
                  "KMD_CFG_IF_ID_POOL_NO_INTERFACE",
                  "KMD_CFG_IF_ID_POOL_RETURN_FAILED",
                  "KMD_DPD_FAILOVER_MANUAL_TUNNEL",
                  "KMD_DPD_FAILOVER_MAX_ATTEMPTS",
                  "KMD_DPD_FAILOVER_NO_ACTIVE_PEER",
                  "KMD_DPD_FAILOVER_NO_BACKUP_PEER",
                  "KMD_DPD_FAILOVER_NO_TUNNEL_CFG",
                  "KMD_DPD_REMOTE_ADDRESS_CHANGED",
                  "KMD_PM_IKE_SRV_NOT_FOUND_DELETE",
                  "KMD_PM_PHASE1_GROUP_UNSPECIFIED",
                  "KMD_PM_PHASE1_POLICY_SEARCH_FAIL",
                  "KMD_PM_PHASE2_POLICY_LOOKUP_FAIL",
                  "KMD_PM_PROTO_INVALID",
                  "KMD_PM_PROTO_IPCOMP_UNSUPPORTED",
                  "KMD_PM_PROTO_ISAKMP_RESV_UNSUPP",
                  "KMD_PM_SA_CFG_NOT_FOUND",
                  "KMD_PM_SA_ESTABLISHED",
                  "KMD_PM_SA_INDEX_GEN_FAILED",
                  "KMD_PM_SA_PEER_NOT_FOUND",
                  "KMD_PM_UNINITIALIZE_FAILED",
                  "KMD_SNMP_EXTRA_RESPONSE",
                  "KMD_SNMP_FATAL_ERROR",
                  "KMD_SNMP_MALLOC_FAILED",
                  "KMD_SNMP_PIC_CONNECTION_FAILED",
                  "KMD_SNMP_PIC_NO_RESPONSE",
                  "KMD_SNMP_PIC_SLOT_NOT_FOUND",
                  "KMD_VPN_DFBIT_STATUS_MSG",
                  "KMD_VPN_DOWN_ALARM_USER",
                  "KMD_VPN_PV_LIFETIME_CHANGED",
                  "KMD_VPN_PV_PHASE1",
                  "KMD_VPN_PV_PHASE2",
                  "KMD_VPN_PV_PSK_CHANGED",
                  "KMD_VPN_UP_ALARM_USER"
              };
              return names;
        }
};

class L2ALDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "L2ALD" );
        }

        vector<string>& GetFacilityNames()
        {
              static vector<string> names =
              {
                  "L2ALD_BD_NAME_RESTRICTION",
                  "L2ALD_DUPLICATE_RBEB_MAC",
                  "L2ALD_FREE_MAC_FAILED",
                  "L2ALD_GENCFG_OP_FAILED",
                  "L2ALD_IPC_MESSAGE_ERROR",
                  "L2ALD_IPC_MESSAGE_INVALID",
                  "L2ALD_IPC_MESSAGE_SEND_FAILED",
                  "L2ALD_IPC_PIPE_WRITE_ERROR",
                  "L2ALD_MAC_LIMIT_REACHED_BD",
                  "L2ALD_MAC_LIMIT_REACHED_GLOBAL",
                  "L2ALD_MAC_LIMIT_REACHED_IF",
                  "L2ALD_MAC_LIMIT_REACHED_IFBD",
                  "L2ALD_MAC_LIMIT_REACHED_RTT",
                  "L2ALD_MAC_LIMIT_RESET_BD",
                  "L2ALD_MAC_LIMIT_RESET_GLOBAL",
                  "L2ALD_MAC_LIMIT_RESET_IF",
                  "L2ALD_MAC_LIMIT_RESET_RTT",
                  "L2ALD_MAC_MOVE_NOTIFICATION",
                  "L2ALD_MALLOC_FAILED",
                  "L2ALD_MANAGER_CONNECT",
                  "L2ALD_NAME_LENGTH_IF_DEVICE",
                  "L2ALD_NAME_LENGTH_IF_FAMILY",
                  "L2ALD_NAME_LENGTH_IF_LOGICAL",
                  "L2ALD_PBBN_IFL_REVA",
                  "L2ALD_PBBN_REINSTATE_IFBDS",
                  "L2ALD_PBBN_RETRACT_IFBDS",
                  "L2ALD_PIP_IFD_READ_RETRY"
              };
              return names;
        }
};

class L2CPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "L2CPD" );
        }

        vector<string>& GetFacilityNames()
        {
              static vector<string> names =
              {
                  "L2CPD_ASSERT",
                  "L2CPD_ASSERT_SOFT",
                  "L2CPD_EXIT",
                  "L2CPD_KERNEL_VERSION",
                  "L2CPD_KERNEL_VERSION_OLD",
                  "L2CPD_KERNEL_VERSION_UNSUPP",
                  "L2CPD_MEMORY_EXCESSIVE",
                  "L2CPD_MGMT_TIMEOUT",
                  "L2CPD_MIRROR_ERROR",
                  "L2CPD_MIRROR_VERSION_MISMATCH",
                  "L2CPD_PPM_READ_ERROR",
                  "L2CPD_PPM_WRITE_ERROR",
                  "L2CPD_RUNTIME_MODULE",
                  "L2CPD_RUNTIME_OPERATION",
                  "L2CPD_RUNTIME_TASK",
                  "L2CPD_TASK_BEGIN",
                  "L2CPD_TASK_CHILD_KILLED",
                  "L2CPD_TASK_CHILD_STOPPED",
                  "L2CPD_TASK_FORK",
                  "L2CPD_TASK_GETWD",
                  "L2CPD_TASK_MASTERSHIP",
                  "L2CPD_TASK_NO_REINIT",
                  "L2CPD_TASK_PID_CLOSE",
                  "L2CPD_TASK_PID_LOCK",
                  "L2CPD_TASK_PID_WRITE",
                  "L2CPD_TASK_REINIT",
                  "L2CPD_TERMINATE_ACTIVE",
                  "L2CPD_TERMINATE_SIGNAL",
                  "L2CPD_TRACE_FAILED",
                  "L2CPD_XSTP_SHUTDOWN_FAILED"
              };
              return names;
        }
};

class L2TPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "L2TPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "L2TPD_COS_PROFILE_ADD",
                "L2TPD_COS_PROFILE_DELETE",
                "L2TPD_DB_ADD_FAILED",
                "L2TPD_DB_DELETE_FAILED",
                "L2TPD_DB_INIT_FAILED",
                "L2TPD_DB_TUN_GRP_ALLOC_FAILED",
                "L2TPD_DEFAULT_PROTO_CREATE_FAIL",
                "L2TPD_EVLIB_CREATE_FAILED",
                "L2TPD_EVLIB_FD_DEREGISTER_FAILED",
                "L2TPD_EVLIB_FD_DESELECT_FAILED",
                "L2TPD_EVLIB_FD_NOT_REGISTERED",
                "L2TPD_EVLIB_FD_SELECT_FAILED",
                "L2TPD_EVLIB_TIMER_CLEAR_FAILED",
                "L2TPD_EVLIB_TIMER_SET_FAILED",
                "L2TPD_FILTER_FILE_OPEN_FAILED",
                "L2TPD_GLOBAL_CFG_ADD_FAILED",
                "L2TPD_GLOBAL_CFG_CHANGE_FAILED",
                "L2TPD_GLOBAL_CFG_DELETE_FAILED",
                "L2TPD_IFD_ADD_FAILED",
                "L2TPD_IFD_DELETE_FAILED",
                "L2TPD_IFD_MSG_REGISTER_FAILED",
                "L2TPD_IFD_ROOT_ALLOC_FAILED",
                "L2TPD_IFL_ADD_FAILED",
                "L2TPD_IFL_DELETE_FAILED",
                "L2TPD_IFL_MSG_REGISTER_FAILED",
                "L2TPD_IFL_NOT_FOUND",
                "L2TPD_IFL_ROOT_ALLOC_FAILED",
                "L2TPD_INSTANCE_CREATE_FAILED",
                "L2TPD_INSTANCE_RESTART_FAILED",
                "L2TPD_INTERFACE_ID_NOT_FOUND",
                "L2TPD_MESSAGE_REGISTER_FAILED",
                "L2TPD_MLPPP_BUNDLE_ALLOC_FAILED",
                "L2TPD_MLPPP_BUNDLE_CREATE_FAILED",
                "L2TPD_MLPPP_BUNDLE_INVALID_ID",
                "L2TPD_MLPPP_COPY_CFG_FAILED",
                "L2TPD_MLPPP_ID_ALLOC_FAILED",
                "L2TPD_MLPPP_ID_BITMAP_ALLOC_FAIL",
                "L2TPD_MLPPP_ID_NODE_ADD_FAILED",
                "L2TPD_MLPPP_ID_ROOT_ALLOC_FAILED",
                "L2TPD_MLPPP_LINK_CREATE_FAILED",
                "L2TPD_MLPPP_LINK_MAX_EXCEEDED",
                "L2TPD_MLPPP_POOL_ADDRESS_FAILED",
                "L2TPD_MLPPP_SESSION_CREATE_FAIL",
                "L2TPD_MLPPP_SESSION_DELETE_FAIL",
                "L2TPD_MLPPP_SPEED_MISMATCH",
                "L2TPD_NH_DELETE_FAILED",
                "L2TPD_POLICER_ADD_FAILED",
                "L2TPD_POLICER_PROFILE_DEL_FAILED",
                "L2TPD_POOL_ADDRESS_FAILED",
                "L2TPD_POOL_ASSIGN_ADDRESS_FAILED",
                "L2TPD_PPP_ROUTE_ADD_FAILED",
                "L2TPD_PPP_ROUTE_DELETE_FAILED",
                "L2TPD_PROFILE_NOT_FOUND",
                "L2TPD_PROFILE_NO_RADIUS_SERVERS",
                "L2TPD_RADIUS_ACCT_PORT_ZERO",
                "L2TPD_RADIUS_GETHOSTNAME_FAILED",
                "L2TPD_RADIUS_RT_INST_ENOENT",
                "L2TPD_RADIUS_RT_INST_NOT_FOUND",
                "L2TPD_RADIUS_SERVER_NOT_FOUND",
                "L2TPD_RADIUS_SRC_ADDR_BIND_FAIL",
                "L2TPD_RADIUS_SRC_ADDR_ENOENT",
                "L2TPD_RPD_ASYNC_UNREG_FAILED",
                "L2TPD_RPD_ROUTE_ADD_CB_FAILED",
                "L2TPD_RPD_ROUTE_ADD_FAILED",
                "L2TPD_RPD_ROUTE_DELETE_CB_FAILED",
                "L2TPD_RPD_ROUTE_DELETE_FAILED",
                "L2TPD_RPD_ROUTE_PREFIX_TOO_LONG",
                "L2TPD_RPD_SESS_CREATE_FAILED",
                "L2TPD_RPD_SESS_HANDLE_ALLOC_FAIL",
                "L2TPD_RPD_SOCKET_ALLOC_FAILED",
                "L2TPD_RPD_TBL_LOCATE_BY_NAME",
                "L2TPD_RPD_TBL_LOCATE_FAILED",
                "L2TPD_RPD_VERSION_MISMATCH",
                "L2TPD_RTSLIB_ASYNC_OPEN_FAILED",
                "L2TPD_RTSLIB_OPEN_FAILED",
                "L2TPD_SERVER_START_FAILED",
                "L2TPD_SERVICE_NH_ADD_FAILED",
                "L2TPD_SERVICE_NH_DELETE_FAILED",
                "L2TPD_SESSION_CFG_ADD_ERROR",
                "L2TPD_SESSION_CFG_ADD_FAILED",
                "L2TPD_SESSION_CFG_DELETE_FAILED",
                "L2TPD_SESSION_DELETE_FAILED",
                "L2TPD_SESSION_IFF_NOT_FOUND",
                "L2TPD_SESSION_IFL_ADD_FAILED",
                "L2TPD_SESSION_IFL_ALLOC_FAILED",
                "L2TPD_SESSION_IFL_CLI_TREE_ALLOC",
                "L2TPD_SESSION_IFL_DELETED",
                "L2TPD_SESSION_IFL_DELETE_FAILED",
                "L2TPD_SESSION_IFL_GET_FAILED",
                "L2TPD_SESSION_IFL_NOT_EQUAL",
                "L2TPD_SESSION_IFL_NOT_FOUND",
                "L2TPD_SESSION_IFL_OCCUPIED",
                "L2TPD_SESSION_IFL_REMOVE_FAILED",
                "L2TPD_SESSION_INVALID_PEER_IP",
                "L2TPD_SESSION_IP_DUPLICATE",
                "L2TPD_SESSION_ROUTE_ADD_FAILED",
                "L2TPD_SESSION_RT_TBL_NOT_FOUND",
                "L2TPD_SESSION_TUNNEL_ID_MISMATCH",
                "L2TPD_SETSOCKOPT_FAILED",
                "L2TPD_SET_ASYNC_CONTEXT",
                "L2TPD_SHOW_MULTILINK",
                "L2TPD_SHOW_SESSION",
                "L2TPD_SHOW_TUNNEL",
                "L2TPD_SOCKET_FAILED",
                "L2TPD_SUBUNIT_ROUTE_ALLOC_FAILED",
                "L2TPD_TRACE_FILE_OPEN_FAILED",
                "L2TPD_TUNNEL_CFG_ADD_FAILED",
                "L2TPD_TUNNEL_CFG_ADD_INV_ADDR",
                "L2TPD_TUNNEL_CFG_DELETE_FAILED",
                "L2TPD_TUNNEL_DELETE_FAILED",
                "L2TPD_TUNNEL_DEST_IF_LOOKUP_FAIL",
                "L2TPD_TUNNEL_GROUP_ADD_FAILED",
                "L2TPD_TUNNEL_GROUP_CFG_ADD_FAIL",
                "L2TPD_TUNNEL_GROUP_CFG_DEL_FAIL",
                "L2TPD_TUNNEL_GROUP_CREATE_FAILED",
                "L2TPD_TUNNEL_GROUP_DELETE_FAILED",
                "L2TPD_TUNNEL_GROUP_IDX_MISMATCH",
                "L2TPD_TUNNEL_GROUP_RESTART_FAIL",
                "L2TPD_USER_AUTHN_NOT_FOUND",
                "L2TPD_USER_AUTHN_ORDER_UNKNOWN",
                "L2TPD_USER_AUTHN_PWD_NOT_FOUND"
            };
            return names;
        }
};

class LACPGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "LACP" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "LACP_INTF_DOWN"
            };
            return names;
        }
};


class LACPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "LACPD " );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "LACPD_MEMORY_ALLOCATION_FAILED",
                "LACPD_MEMORY_ALLOCATION_FAILED",
                "LACPD_TIMEOUT"
            };
            return names;
        }
};

class LFMDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "LFMD" );
        }

        vector<string>& GetFacilityNames()
        {
          static vector<string> names =
          {
              "LFMD_RTSOCK_OPEN_FAILED",
          };
          return names;
        }
};

class LIBJNXGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "LIBJNX" );
        }

        vector<string>& GetFacilityNames()
        {
          static vector<string> names =
          {
              "LIBJNX_SNMP_ENGINE_FILE_FAILURE"
          };
          return names;
        }
};

class LIBJSNMPGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "LIBJSNMP" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
               "LIBJSNMP_CTX_FAILURE",
               "LIBJSNMP_IPC_ERROR",
               "LIBJSNMP_IPC_READ_ERROR",
               "LIBJSNMP_MTHD_API_UNKNOWN_TYPE",
               "LIBJSNMP_NS_LOG_CRIT",
               "LIBJSNMP_NS_LOG_EMERG",
               "LIBJSNMP_NS_LOG_ERR",
               "LIBJSNMP_OID_GEN_FAILED",
               "LIBJSNMP_READ_LEN_ERR",
               "LIBJSNMP_RTMSIZE_MISMATCH_ERR",
               "LIBJSNMP_SMS_HDR_ERR",
               "LIBJSNMP_SMS_MSG_ERR",
               "LIBJSNMP_SOCKET_OPEN_ERR",
               "LIBJSNMP_SOCKET_VER_MISMATCH",
               "LIBJSNMP_TRAP_API_FAILURE",
               "LIBJSNMP_TRAP_UTILS_ERR"
            };
            return names;
        }
};

class LIBMSPRPCGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "LIBMSPRPC" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "LIBMSPRPC_CLIENT_INIT_FAILED",
                "LIBMSPRPC_CLIENT_KCOM_FAILED",
                "LIBMSPRPC_CLIENT_KCOM_NO_IF",
                "LIBMSPRPC_CLIENT_NO_CONNECTION",
                "LIBMSPRPC_CLIENT_NO_REPLY",
                "LIBMSPRPC_CLIENT_PIC_DOWN",
                "LIBMSPRPC_CLIENT_WRONG_OUTPUT"
            };
            return names;
        }
};

class LICENSEGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "LICENSE" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "LICENSE_CONNECT_FAILURE",
                "LICENSE_CONN_TO_LI_CHECK_FAILURE",
                "LICENSE_CONN_TO_LI_CHECK_SUCCESS",
                "LICENSE_EXPIRED",
                "LICENSE_EXPIRED_KEY_DELETED",
                "LICENSE_GRACE_PERIOD_APPROACHING",
                "LICENSE_GRACE_PERIOD_EXCEEDED",
                "LICENSE_GRACE_PERIOD_EXPIRED",
                "LICENSE_LIST_MANAGEMENT",
                "LICENSE_NEARING_EXPIRY",
                "LICENSE_READ_ERROR",
                "LICENSE_REG_ERROR",
                "LICENSE_SHM_ATTACH_FAILURE",
                "LICENSE_SHM_CREATE_FAILURE",
                "LICENSE_SHM_DETACH_FAILURE",
                "LICENSE_SHM_FILE_OPEN_FAILURE",
                "LICENSE_SHM_KEY_CREATE_FAILURE",
                "LICENSE_SHM_SCALE_READ_FAILURE",
                "LICENSE_SHM_SCALE_UPDATE_FAILURE",
                "LICENSE_SIGNATURE_VERIFY_FAILED",
                "LICENSE_UNKNOWN_RESPONSE_TYPE",
                "LICENSE_VERIFICATION_FILE_ERROR"
            };
            return names;
        }
};

class LOGINGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "LOGIN" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "LOGIN_ABORTED",
                "LOGIN_ATTEMPTS_THRESHOLD",
                "LOGIN_FAILED",
                "LOGIN_FAILED_LIMIT",
                "LOGIN_FAILED_SET_CONTEXT",
                "LOGIN_FAILED_SET_LOGIN",
                "LOGIN_HOSTNAME_UNRESOLVED",
                "LOGIN_INFORMATION",
                "LOGIN_MALFORMED_USER",
                "LOGIN_PAM_AUTHENTICATION_ERROR",
                "LOGIN_PAM_ERROR",
                "LOGIN_PAM_MAX_RETRIES",
                "LOGIN_PAM_STOP",
                "LOGIN_PAM_USER_UNKNOWN",
                "LOGIN_PASSWORD_EXPIRED",
                "LOGIN_REFUSED",
                "LOGIN_ROOT",
                "LOGIN_TIMED_OUT"
            };
            return names;
        }
};

class LPDFDGroup : public IJunosFacilityGroup
{
  public:
        string GetGroupName()
        {
            return string( "LPDFD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "LPDFD_DYN_PDB_OPEN_FAILED",
                "LPDFD_DYN_REGISTER_FAILED",
                "LPDFD_PCONN_SERVER"
            };
            return names;
        }
};

class LRMUXGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "LRMUX" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "LRMUX_FAILED_EXEC",
                "LRMUX_LRPD_PID_LOCK",
                "LRMUX_LRPD_PID_OPEN",
                "LRMUX_LRPD_SEND_HUP",
                "LRMUX_PID_LOCK"
            };
            return names;
        }
};

class LSYSDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "LSYSD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "LSYSD_CFG_RD_FAILED",
                "LSYSD_INIT_FAILED",
                "LSYSD_LICENSE_INIT_FAILED",
                "LSYSD_SEC_NODE_COMP_SYNC_FAILED"
            };
            return names;
        }
};

class MCSNGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "MCSN" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
               "MCSN_ABORT",
               "MCSN_ACTIVE_TERMINATE",
               "MCSN_ASSERT",
               "MCSN_ASSERT_SOFT",
               "MCSN_EXIT",
               "MCSN_SCHED_CALLBACK_LONGRUNTIME",
               "MCSN_SCHED_CUMULATVE_LNGRUNTIME",
               "MCSN_SIGNAL_TERMINATE",
               "MCSN_START",
               "MCSN_SYSTEM",
               "MCSN_TASK_BEGIN",
               "MCSN_TASK_CHILDKILLED",
               "MCSN_TASK_CHILDSTOPPED",
               "MCSN_TASK_FORK",
               "MCSN_TASK_GETWD",
               "MCSN_TASK_MASTERSHIP",
               "MCSN_TASK_NOREINIT",
               "MCSN_TASK_REINIT",
               "MCSN_TASK_SIGNALIGNORE"
            };
            return names;
        }
};

class MCSNOOPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "MCSNOOPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "MCSNOOPD_MGMT_TIMEOUT"
            };
            return names;
        }
};

class MIB2DGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "MIB2D" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "MIB2D_ATM_ERROR",
                "MIB2D_CONFIG_CHECK_FAILED",
                "MIB2D_FILE_OPEN_FAILURE",
                "MIB2D_IFD_IFDINDEX_FAILURE",
                "MIB2D_IFD_IFINDEX_FAILURE",
                "MIB2D_IFL_IFINDEX_FAILURE",
                "MIB2D_IF_FLAPPING_MISSING",
                "MIB2D_KVM_FAILURE",
                "MIB2D_PMON_OVERLOAD_CLEARED_TRAP",
                "MIB2D_PMON_OVERLOAD_SET_TRAP",
                "MIB2D_RTSLIB_READ_FAILURE",
                "MIB2D_RTSLIB_SEQ_MISMATCH",
                "MIB2D_SNMP_INDEX_ASSIGN",
                "MIB2D_SNMP_INDEX_DUPLICATE",
                "MIB2D_SNMP_INDEX_UPDATE_STAT",
                "MIB2D_SNMP_INDEX_WRITE",
                "MIB2D_SYSCTL_FAILURE",
                "MIB2D_TRAP_HEADER_FAILURE",
                "MIB2D_TRAP_SEND_FAILURE"
            };
            return names;
        }
};

class MPLS_OAMGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "MPLS_OAM" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "MPLS_OAM_FANOUT_LIMIT_REACHED",
                "MPLS_OAM_INVALID_SOURCE_ADDRESS",
                "MPLS_OAM_PATH_LIMIT_REACHED",
                "MPLS_OAM_SEND_FAILED",
                "MPLS_OAM_SOCKET_OPEN_FAILED",
                "MPLS_OAM_SOCKET_SELECT_FAILED",
                "MPLS_OAM_TRACEROUTE_INTERRUPTED",
                "MPLS_OAM_TTL_EXPIRED",
                "MPLS_OAM_UNREACHABLE"
            };
            return names;
        }
};

class NEXTHOPGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "NEXTHOP" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "NEXTHOP_COMPONENTS_LIMIT_REACHED"
            };
            return names;
        }
};

class NSDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "NSD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "NSD_MEMORY_ALLOC_FAILED",
                "NSD_RESTART_COMP_CFG_READ_FAILED",
                "NSD_SEC_NODE_COMP_SYNC_FAILED"
            };
            return names;
        }
};

class NSTRACEDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "NSTRACED" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "NSTRACED_MEMORY_ALLOC_FAILED",
                "NSTRACED_RESTART_CFG_READ_FAILED"
            };
            return names;
        }
};

class NTPDATEGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "NTPDATE" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "NTPDATE_TIME_CHANGED"
            };
            return names;
        }
};

class NTPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "NTPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "NTPD_CHANGED_TIME"
            };
            return names;
        }
};

class PFEGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "PFE" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "PFE_ANALYZER_CFG_FAILED",
                "PFE_ANALYZER_SHIM_CFG_FAILED",
                "PFE_ANALYZER_TABLE_WRITE_FAILED",
                "PFE_ANALYZER_TASK_FAILED",
                "PFE_CBF_UNSUPPORTED",
                "PFE_COS_B2_ONE_CLASS",
                "PFE_COS_B2_UNSUPPORTED",
                "PFE_FW_DELETE_MISMATCH_ERR",
                "PFE_FW_IF_DIALER_ERR",
                "PFE_FW_IF_INPUT_ERR",
                "PFE_FW_IF_OUTPUT_ERR",
                "PFE_FW_PSF_DELETE_MISMATCH_ERR",
                "PFE_FW_SYSLOG_ETH",
                "PFE_FW_SYSLOG_IP",
                "PFE_FW_SYSLOG_IP6_GEN",
                "PFE_FW_SYSLOG_IP6_ICMP",
                "PFE_FW_SYSLOG_IP6_TCP_UDP",
                "PFE_MGCP_MEM_INIT_FAILED",
                "PFE_MGCP_REG_HDL_FAIL",
                "PFE_NH_RESOLVE_THROTTLED",
                "PFE_SCCP_ADD_PORT_FAIL",
                "PFE_SCCP_DEL_PORT_FAIL",
                "PFE_SCCP_REG_NAT_VEC_FAIL",
                "PFE_SCCP_REG_RM_FAIL",
                "PFE_SCCP_REG_VSIP_FAIL",
                "PFE_SCCP_RM_CLIENTID_FAIL",
                "PFE_SCREEN_MT_CFG_ERROR",
                "PFE_SCREEN_MT_CFG_EVENT",
                "PFE_SCREEN_MT_ZONE_BINDING_ERROR",
                "PFE_SIP_MEM_INIT_FAILED",
                "PFE_SIP_REG_HDL_FAIL"
            };
            return names;
        }
};

class PFEDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "PFED" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                  "PFED_NOTIFICATION_STATS_FAILED"
            };
            return names;
        }
};

class PGCPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "PGCPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "PGCPD_SHUTDOWN",
                "PGCPD_STARTUP",
                "PGCPD_SWITCH_OVER"
            };
            return names;
        }
};

class PINGGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "PING" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "PING_EGRESS_JITTER_THRESH_EXCEED",
                "PING_EGRESS_STDDEV_THRESH_EXCEED",
                "PING_EGRESS_THRESHOLD_EXCEEDED",
                "PING_INGRESS_JTR_THRESH_EXCEED",
                "PING_INGRESS_STDDV_THRESH_EXCEED",
                "PING_INGRESS_THRESHOLD_EXCEEDED",
                "PING_PROBE_FAILED",
                "PING_RTT_JTR_THRESH_EXCEED",
                "PING_RTT_STDDV_THRESH_EXCEED",
                "PING_RTT_THRESHOLD_EXCEEDED",
                "PING_TEST_COMPLETED",
                "PING_TEST_FAILED",
                "PING_UNKNOWN_THRESH_TYPE_EXCEED"
            };
            return names;
        }
};

class PKIDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "PKID" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "PKID_AFTER_KEY_GEN_SELF_TEST",
                "PKID_CORRUPT_CERT",
                "PKID_FIPS_KAT_SUCCESS",
                "PKID_PV_ASYM_KEYGEN",
                "PKID_PV_CERT_DEL",
                "PKID_PV_CERT_LOAD",
                "PKID_PV_KEYPAIR_DEL",
                "PKID_PV_KEYPAIR_GEN",
                "PKID_PV_OBJECT_READ"
            };
            return names;
        }
};

class PPMDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "PPMD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "PPMD_ASSERT_SOFT",
                "PPMD_OPEN_ERROR",
                "PPMD_READ_ERROR",
                "PPMD_WRITE_ERROR"
            };
            return names;
        }
};

class PPPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "PPPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "PPPD_AUTH_CREATE_FAILED",
                "PPPD_CHAP_AUTH_IN_PROGRESS",
                "PPPD_CHAP_GETHOSTNAME_FAILED",
                "PPPD_CHAP_INVALID_IDENTIFIER",
                "PPPD_CHAP_INVALID_OPCODE",
                "PPPD_CHAP_LOCAL_NAME_UNAVAILABLE",
                "PPPD_CHAP_OPERATION_UNEXPECTED",
                "PPPD_CHAP_REPLAY_ATTACK_DETECTED",
                "PPPD_EVLIB_CREATE_FAILURE",
                "PPPD_LOCAL_CREATE_FAILED",
                "PPPD_MEMORY_ALLOCATION_FAILURE",
                "PPPD_PAP_GETHOSTNAME_FAILED",
                "PPPD_PAP_INVALID_IDENTIFIER",
                "PPPD_PAP_INVALID_OPCODE",
                "PPPD_PAP_LOCAL_PASSWORD_UNAVAIL",
                "PPPD_PAP_OPERATION_UNEXPECTED",
                "PPPD_POOL_ADDRESSES_EXHAUSTED",
                "PPPD_RADIUS_ADD_SERVER_FAILED",
                "PPPD_RADIUS_ALLOC_PASSWD_FAILED",
                "PPPD_RADIUS_CREATE_FAILED",
                "PPPD_RADIUS_CREATE_REQ_FAILED",
                "PPPD_RADIUS_GETHOSTNAME_FAILED",
                "PPPD_RADIUS_MESSAGE_UNEXPECTED",
                "PPPD_RADIUS_NO_VALID_SERVERS",
                "PPPD_RADIUS_OPEN_FAILED",
                "PPPD_RADIUS_ROUTE_INST_ENOENT"
            };
            return names;
        }
};

class PROFILERGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "PROFILER" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "PROFILER_RECONFIGURE_SIGHUP"
            };
            return names;
        }
};

class RDDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "RDD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "RDD_EVLIB_CREATE_FAILURE"
                "RDD_IFDEV_ADD_FAILURE"
                "RDD_IFDEV_DELETE_FAILURE"
                "RDD_IFDEV_GET_FAILURE"
                "RDD_IFDEV_INCOMPATIBLE_REVERT"
                "RDD_IFDEV_INCOMPATIBLE_SWITCH"
                "RDD_IFDEV_RETRY_NOTICE"
                "RDD_NEW_INTERFACE_STATE"
            };
            return names;
        }
};

class RMOPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "RMOPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "RMOPD_ADDRESS_MULTICAST_INVALID",
                "RMOPD_ADDRESS_SOURCE_INVALID",
                "RMOPD_ADDRESS_STRING_FAILURE",
                "RMOPD_ADDRESS_TARGET_INVALID",
                "RMOPD_ICMP_ADDR_TYPE_UNSUPPORTED",
                "RMOPD_IFINDEX_NOT_ACTIVE",
                "RMOPD_IFINDEX_NO_INFO",
                "RMOPD_IFNAME_NOT_ACTIVE",
                "RMOPD_IFNAME_NO_INFO",
                "RMOPD_ROUTING_INSTANCE_NO_INFO",
                "RMOPD_TRACEROUTE_ERROR"
            };
            return names;
        }
};

class RPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "RPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "RPD_ABORT",
                "RPD_ACTIVE_TERMINATE",
                "RPD_AMT_CFG_ADDR_FMLY_INVALID",
                "RPD_AMT_CFG_ANYCAST_INVALID",
                "RPD_AMT_CFG_ANYCAST_MCAST",
                "RPD_AMT_CFG_LOC_ADDR_INVALID",
                "RPD_AMT_CFG_LOC_ADDR_MCAST",
                "RPD_AMT_CFG_PREFIX_LEN_SHORT",
                "RPD_AMT_CFG_RELAY_INVALID",
                "RPD_AMT_RELAY_DISCOVERY",
                "RPD_AMT_TUNNEL_CREATE",
                "RPD_AMT_TUNNEL_DELETE",
                "RPD_ASSERT",
                "RPD_ASSERT_SOFT",
                "RPD_BFD_READ_ERROR",
                "RPD_BFD_WRITE_ERROR",
                "RPD_BGP_CFG_ADDR_INVALID",
                "RPD_BGP_CFG_LOCAL_ASNUM_WARN",
                "RPD_BGP_NEIGHBOR_STATE_CHANGED",
                "RPD_CFG_TRACE_FILE_MISSING",
                "RPD_DYN_CFG_BUSY_SIGNAL_FAILED",
                "RPD_DYN_CFG_GET_PROFILE_FAILED",
                "RPD_DYN_CFG_GET_PROF_NAME_FAILED",
                "RPD_DYN_CFG_GET_SES_STATE_FAILED",
                "RPD_DYN_CFG_GET_SES_TYPE_FAILED",
                "RPD_DYN_CFG_GET_SNAPSHOT_FAILED",
                "RPD_DYN_CFG_PDB_CLOSE_FAILED",
                "RPD_DYN_CFG_PDB_OPEN_FAILED",
                "RPD_DYN_CFG_PROCESSING_FAILED",
                "RPD_DYN_CFG_REGISTER_FAILED",
                "RPD_DYN_CFG_REQUEST_ACK_FAILED",
                "RPD_DYN_CFG_RESPONSE_SLOW",
                "RPD_DYN_CFG_SCHEMA_OPEN_FAILED",
                "RPD_DYN_CFG_SES_RECOVERY_FAILED",
                "RPD_DYN_CFG_SET_CONTEXT_FAILED",
                "RPD_DYN_CFG_SMID_RECOVERY_FAILED",
                "RPD_DYN_CFG_SMID_REG_FAILED",
                "RPD_DYN_CFG_SMID_UNREG_FAILED",
                "RPD_ESIS_ADJDOWN",
                "RPD_ESIS_ADJUP",
                "RPD_EXIT",
                "RPD_IFD_INDEXCOLLISION",
                "RPD_IFD_NAMECOLLISION",
                "RPD_IFL_INDEXCOLLISION",
                "RPD_IFL_NAMECOLLISION",
                "RPD_IGMP_ACCOUNTING_OFF",
                "RPD_IGMP_ACCOUNTING_ON",
                "RPD_IGMP_ALL_SUBSCRIBERS_DELETED",
                "RPD_IGMP_CFG_CREATE_ENTRY_FAILED",
                "RPD_IGMP_CFG_GROUP_OUT_OF_RANGE",
                "RPD_IGMP_CFG_INVALID_VALUE",
                "RPD_IGMP_CFG_SOURCE_OUT_OF_RANGE",
                "RPD_IGMP_DYN_CFG_ALREADY_BOUND",
                "RPD_IGMP_DYN_CFG_INVALID_STMT",
                "RPD_IGMP_DYN_CFG_SES_ID_ADD_FAIL",
                "RPD_IGMP_DYN_CFG_SES_ID_MISMATCH",
                "RPD_IGMP_JOIN",
                "RPD_IGMP_LEAVE",
                "RPD_IGMP_MEMBERSHIP_TIMEOUT",
                "RPD_IGMP_ROUTER_VERSION_MISMATCH",
                "RPD_ISIS_ADJDOWN",
                "RPD_ISIS_ADJUP",
                "RPD_ISIS_ADJUPNOIP",
                "RPD_ISIS_LDP_SYNC",
                "RPD_ISIS_LSPCKSUM",
                "RPD_ISIS_NO_ROUTERID",
                "RPD_ISIS_OVERLOAD",
                "RPD_KRT_CCC_IFL_MODIFY",
                "RPD_KRT_DELETED_RTT",
                "RPD_KRT_IFA_GENERATION",
                "RPD_KRT_IFDCHANGE",
                "RPD_KRT_IFDEST_GET",
                "RPD_KRT_IFDGET",
                "RPD_KRT_IFD_CELL_RELAY_INV_MODE",
                "RPD_KRT_IFD_CELL_RELAY_NO_MODE",
                "RPD_KRT_IFD_GENERATION",
                "RPD_KRT_IFL_CELL_RELAY_INV_MODE",
                "RPD_KRT_IFL_CELL_RELAY_NO_MODE",
                "RPD_KRT_IFL_GENERATION",
                "RPD_KRT_KERNEL_BAD_ROUTE",
                "RPD_KRT_NEXTHOP_OVERFLOW",
                "RPD_KRT_NOIFD",
                "RPD_KRT_VERSION",
                "RPD_KRT_VERSIONNONE",
                "RPD_KRT_VERSIONOLD",
                "RPD_KRT_VPLS_IFL_MODIFY",
                "RPD_L2VPN_LABEL_ALLOC_FAILED",
                "RPD_L2VPN_REMOTE_SITE_COLLISION",
                "RPD_L2VPN_SITE_COLLISION",
                "RPD_LAYER2_VC_BFD_DOWN",
                "RPD_LAYER2_VC_BFD_UP",
                "RPD_LAYER2_VC_DOWN",
                "RPD_LAYER2_VC_PING_DOWN",
                "RPD_LAYER2_VC_UP",
                "RPD_LDP_BFD_DOWN",
                "RPD_LDP_BFD_DOWN_TRACEROUTE_FAIL",
                "RPD_LDP_BFD_UP",
                "RPD_LDP_GR_CFG_IGNORED",
                "RPD_LDP_INTF_BLOCKED",
                "RPD_LDP_INTF_UNBLOCKED",
                "RPD_LDP_NBRDOWN",
                "RPD_LDP_NBRUP",
                "RPD_LDP_PING_DOWN",
                "RPD_LDP_SESSIONDOWN",
                "RPD_LDP_SESSIONUP",
                "RPD_LMP_ALLOC_ACK",
                "RPD_LMP_ALLOC_REQUEST_TIMEOUT",
                "RPD_LMP_CONTROL_CHANNEL",
                "RPD_LMP_NO_CALLBACK",
                "RPD_LMP_NO_MEMORY",
                "RPD_LMP_NO_PEER",
                "RPD_LMP_PEER",
                "RPD_LMP_PEER_IFL",
                "RPD_LMP_PEER_INDEX",
                "RPD_LMP_RESOURCE",
                "RPD_LMP_RESOURCE_NO_LINK",
                "RPD_LMP_SEND",
                "RPD_LMP_SEND_ALLOCATION_MESSAGE",
                "RPD_LMP_SYSFAIL",
                "RPD_LMP_TE_LINK",
                "RPD_LMP_TE_LINK_INDEX",
                "RPD_LMP_UNEXPECTED_OPCODE",
                "RPD_LOCK_FLOCKED",
                "RPD_LOCK_LOCKED",
                "RPD_MC_CFG_CREATE_ENTRY_FAILED",
                "RPD_MC_CFG_FWDCACHE_CONFLICT",
                "RPD_MC_CFG_PREFIX_LEN_SHORT",
                "RPD_MC_COSD_WRITE_ERROR",
                "RPD_MC_DESIGNATED_PE_CHANGE",
                "RPD_MC_DYN_CFG_ALREADY_BOUND",
                "RPD_MC_DYN_CFG_SES_ID_ADD_FAIL",
                "RPD_MC_DYN_CFG_SES_ID_MISMATCH",
                "RPD_MC_LOCAL_DESIGNATED_PE",
                "RPD_MC_OIF_REJECT",
                "RPD_MC_OIF_RE_ADMIT",
                "RPD_MGMT_TIMEOUT",
                "RPD_MIRROR_ERROR",
                "RPD_MIRROR_VERSION_MISMATCH",
                "RPD_MLD_ACCOUNTING_OFF",
                "RPD_MLD_ACCOUNTING_ON",
                "RPD_MLD_ALL_SUBSCRIBERS_DELETED",
                "RPD_MLD_CFG_CREATE_ENTRY_FAILED",
                "RPD_MLD_CFG_GROUP_OUT_OF_RANGE",
                "RPD_MLD_CFG_INVALID_VALUE",
                "RPD_MLD_CFG_SOURCE_OUT_OF_RANGE",
                "RPD_MLD_DYN_CFG_ALREADY_BOUND",
                "RPD_MLD_DYN_CFG_INVALID_STMT",
                "RPD_MLD_DYN_CFG_SES_ID_ADD_FAIL",
                "RPD_MLD_DYN_CFG_SES_ID_MISMATCH",
                "RPD_MLD_JOIN",
                "RPD_MLD_LEAVE",
                "RPD_MLD_MEMBERSHIP_TIMEOUT",
                "RPD_MLD_ROUTER_VERSION_MISMATCH",
                "RPD_MPLS_INTERFACE_ROUTE_ERROR",
                "RPD_MPLS_INTF_MAX_LABELS_ERROR",
                "RPD_MPLS_LSP_AUTOBW_NOTICE",
                "RPD_MPLS_LSP_BANDWIDTH_CHANGE",
                "RPD_MPLS_LSP_CHANGE",
                "RPD_MPLS_LSP_DOWN",
                "RPD_MPLS_LSP_SWITCH",
                "RPD_MPLS_LSP_UP",
                "RPD_MPLS_OAM_LSP_PING_REPLY_ERR",
                "RPD_MPLS_OAM_PING_REPLY_TIMEOUT",
                "RPD_MPLS_OAM_READ_ERROR",
                "RPD_MPLS_OAM_WRITE_ERROR",
                "RPD_MPLS_PATH_BANDWIDTH_CHANGE",
                "RPD_MPLS_PATH_BFD_DOWN",
                "RPD_MPLS_PATH_BFD_UP",
                "RPD_MPLS_PATH_BW_NOT_AVAILABLE",
                "RPD_MPLS_PATH_DOWN",
                "RPD_MPLS_PATH_PING_DOWN",
                "RPD_MPLS_PATH_UP",
                "RPD_MPLS_REQ_BW_NOT_AVAILABLE",
                "RPD_MPLS_TABLE_ROUTE_ERROR",
                "RPD_MSDP_CFG_SA_LIMITS_CONFLICT",
                "RPD_MSDP_CFG_SRC_INVALID",
                "RPD_MSDP_PEER_DOWN",
                "RPD_MSDP_PEER_UP",
                "RPD_MSDP_SRC_ACTIVE_OVER_LIMIT",
                "RPD_MSDP_SRC_ACTIVE_OVER_THRESH",
                "RPD_MSDP_SRC_ACTIVE_UNDER_LIMIT",
                "RPD_MSDP_SRC_ACTIVE_UNDER_THRESH",
                "RPD_MVPN_CFG_PREFIX_LEN_SHORT",
                "RPD_OSPF_CFGNBR_P2P",
                "RPD_OSPF_IF_COST_CHANGE",
                "RPD_OSPF_LDP_SYNC",
                "RPD_OSPF_LSA_MAXIMUM_EXCEEDED",
                "RPD_OSPF_LSA_WARNING_EXCEEDED",
                "RPD_OSPF_NBRDOWN",
                "RPD_OSPF_NBRUP",
                "RPD_OSPF_OVERLOAD",
                "RPD_OSPF_TOPO_IF_COST_CHANGE",
                "RPD_OS_MEMHIGH",
                "RPD_PARSE_BAD_LR_NAME",
                "RPD_PARSE_BAD_OPTION",
                "RPD_PARSE_CMD_ARG",
                "RPD_PARSE_CMD_DUPLICATE",
                "RPD_PARSE_CMD_EXTRA",
                "RPD_PIM_FOUND_NON_BIDIR_NBR",
                "RPD_PIM_NBRDOWN",
                "RPD_PIM_NBRUP",
                "RPD_PIM_NON_BIDIR_RPF",
                "RPD_PLCY_CFG_COMMUNITY_FAIL",
                "RPD_PLCY_CFG_FWDCLASS_OVERRIDDEN",
                "RPD_PLCY_CFG_IFALL_NOMATCH",
                "RPD_PLCY_CFG_NH_NETMASK",
                "RPD_PLCY_CFG_PARSE_GEN_FAIL",
                "RPD_PLCY_CFG_PREFIX_LEN_SHORT",
                "RPD_PPM_READ_ERROR",
                "RPD_PPM_WRITE_ERROR",
                "RPD_PTHREAD_CREATE",
                "RPD_RA_CFG_CREATE_ENTRY_FAILED",
                "RPD_RA_CFG_INVALID_VALUE",
                "RPD_RA_DYN_CFG_ALREADY_BOUND",
                "RPD_RA_DYN_CFG_INVALID_STMT",
                "RPD_RA_DYN_CFG_SES_ID_ADD_FAIL",
                "RPD_RA_DYN_CFG_SES_ID_MISMATCH",
                "RPD_RDISC_CKSUM",
                "RPD_RDISC_NOMULTI",
                "RPD_RDISC_NORECVIF",
                "RPD_RDISC_SOLICITADDR",
                "RPD_RDISC_SOLICITICMP",
                "RPD_RDISC_SOLICITLEN",
                "RPD_RIP_AUTH_ACK",
                "RPD_RIP_AUTH_REQUEST",
                "RPD_RIP_AUTH_UPDATE",
                "RPD_RIP_JOIN_BROADCAST",
                "RPD_RIP_JOIN_MULTICAST",
                "RPD_RSVP_BACKUP_DOWN",
                "RPD_RSVP_BYPASS_DOWN",
                "RPD_RSVP_BYPASS_UP",
                "RPD_RSVP_COS_CFG_WARN",
                "RPD_RSVP_INCORRECT_FLOWSPEC",
                "RPD_RSVP_LSP_SWITCH",
                "RPD_RSVP_MAXIMUM_SESSIONS",
                "RPD_RSVP_NBRDOWN",
                "RPD_RSVP_NBRUP",
                "RPD_RT_CFG_BR_CONFLICT",
                "RPD_RT_CFG_CREATE_ENTRY_FAILED",
                "RPD_RT_CFG_INVALID_VALUE",
                "RPD_RT_CFG_TABLE_NON_MATCHING",
                "RPD_RT_DUPLICATE_RD",
                "RPD_RT_DYN_CFG_INST_NOT_FOUND",
                "RPD_RT_DYN_CFG_TABLE_NOT_FOUND",
                "RPD_RT_ERROR",
                "RPD_RT_IFUP",
                "RPD_RT_INST_CFG_RESERVED_NAME",
                "RPD_RT_INST_IMPORT_PLCY_WARNING",
                "RPD_RT_PATH_LIMIT_BELOW",
                "RPD_RT_PATH_LIMIT_REACHED",
                "RPD_RT_PATH_LIMIT_WARNING",
                "RPD_RT_PREFIX_LIMIT_BELOW",
                "RPD_RT_PREFIX_LIMIT_REACHED",
                "RPD_RT_PREFIX_LIMIT_WARNING",
                "RPD_RT_SHOWMODE",
                "RPD_RT_TAG_ID_ALLOC_FAILED",
                "RPD_SCHED_CALLBACK_LONGRUNTIME",
                "RPD_SCHED_CUMULATIVE_LONGRUNTIME",
                "RPD_SCHED_MODULE_LONGRUNTIME",
                "RPD_SCHED_TASK_LONGRUNTIME",
                "RPD_SIGNAL_TERMINATE",
                "RPD_SNMP_CONN_PROG",
                "RPD_SNMP_CONN_QUIT",
                "RPD_SNMP_CONN_RETRY",
                "RPD_SNMP_INVALID_SOCKET",
                "RPD_SNMP_SOCKOPT_BLOCK",
                "RPD_SNMP_SOCKOPT_RECVBUF",
                "RPD_SNMP_SOCKOPT_SENDBUF",
                "RPD_START",
                "RPD_SYSTEM",
                "RPD_TASK_BEGIN",
                "RPD_TASK_CHILDKILLED",
                "RPD_TASK_CHILDSTOPPED",
                "RPD_TASK_DYN_REINIT",
                "RPD_TASK_FORK",
                "RPD_TASK_GETWD",
                "RPD_TASK_MASTERSHIP",
                "RPD_TASK_NOREINIT",
                "RPD_TASK_PIDCLOSED",
                "RPD_TASK_PIDFLOCK",
                "RPD_TASK_PIDWRITE",
                "RPD_TASK_REINIT",
                "RPD_TASK_SIGNALIGNORE",
                "RPD_TRACE_FAILED",
                "RPD_VPLS_INTF_NOT_IN_SITE"
            };
            return names;
        }
};

class RTGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "RT" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "RT_FLOW_SESSION_CLOSE",
                "RT_FLOW_SESSION_CLOSE_LS",
                "RT_FLOW_SESSION_CREATE",
                "RT_FLOW_SESSION_CREATE_LS",
                "RT_FLOW_SESSION_DENY",
                "RT_FLOW_SESSION_DENY_LS",
                "RT_H323_NAT_COOKIE_NOT_FOUND",
                "RT_IPSEC_AUTH_FAIL",
                "RT_IPSEC_BAD_SPI",
                "RT_IPSEC_DECRYPT_BAD_PAD",
                "RT_IPSEC_PV_DECRYPTION",
                "RT_IPSEC_PV_ENCRYPTION",
                "RT_IPSEC_PV_REPLAY",
                "RT_IPSEC_PV_SYM_KEYGEN",
                "RT_IPSEC_REPLAY",
                "RT_MGCP_CALL_LIMIT_EXCEED",
                "RT_MGCP_DECODE_FAIL",
                "RT_MGCP_MEM_ALLOC_FAILED",
                "RT_MGCP_REM_NAT_VEC_FAIL",
                "RT_MGCP_RM_CLIENTID_FAIL",
                "RT_MGCP_UNREG_BY_RM",
                "RT_SCCP_CALL_LIMIT_EXCEED",
                "RT_SCCP_CALL_RATE_EXCEED",
                "RT_SCCP_DECODE_FAIL",
                "RT_SCCP_NAT_COOKIE_NOT_FOUND",
                "RT_SCCP_REM_NAT_VEC_FAIL",
                "RT_SCCP_UNREG_RM_FAIL",
                "RT_SCREEN_ICMP",
                "RT_SCREEN_ICMP_LS",
                "RT_SCREEN_IP",
                "RT_SCREEN_IP_LS",
                "RT_SCREEN_SESSION_LIMIT",
                "RT_SCREEN_SESSION_LIMIT_LS",
                "RT_SCREEN_TCP",
                "RT_SCREEN_TCP_DST_IP",
                "RT_SCREEN_TCP_DST_IP_LS",
                "RT_SCREEN_TCP_LS",
                "RT_SCREEN_TCP_SRC_IP",
                "RT_SCREEN_TCP_SRC_IP_LS",
                "RT_SCREEN_UDP",
                "RT_SCREEN_UDP_LS",
                "RT_SCREEN_WHITE_LIST",
                "RT_SCREEN_WHITE_LIST_LS",
                "RT_SCTP_LOG_INFO" ,
                "RT_SCTP_PKT_INFO"
            };
            return names;
        }
};

class RTLOGGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "RTLOG" );
        }

        vector<string>& GetFacilityNames()
        {
              static vector<string> names =
              {
                  "RTLOG_JLOG_TEST",
                  "RTLOG_UTP_TCP_SYN_FLOOD",
                  "RTLOG_UTP_TCP_SYN_FLOOD_LS"
              };
              return names;
        }
};

class RTLOGDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "RTLOGD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "RTLOGD_LOG_BIND_ERROR",
                "RTLOGD_LOG_READ_ERROR"
            };
            return names;
        }
};

class RTPERFGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "RTPERF" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "RTPERF_CPU_THRESHOLD_EXCEEDED",
                "RTPERF_CPU_USAGE_OK"
            };
            return names;
        }
};

class SAVALGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SAVAL" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SAVAL_RTSOCK_FAILURE"
            };
            return names;
        }
};

class SDXDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SDXD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SDXD_BEEP_FIN_FAIL",
                "SDXD_BEEP_INIT_FAIL",
                "SDXD_CHANNEL_START_FAIL",
                "SDXD_CONNECT_FAIL",
                "SDXD_DAEMONIZE_FAIL",
                "SDXD_EVLIB_FAILURE",
                "SDXD_KEEPALIVES_MISSED",
                "SDXD_KEEPALIVE_SEND_FAIL",
                "SDXD_MGMT_SOCKET_IO",
                "SDXD_OUT_OF_MEMORY",
                "SDXD_PID_FILE_UPDATE",
                "SDXD_SOCKET_FAILURE"
            };
            return names;
        }
};

class SFWGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SFW" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SFW_LOG_FUNCTION"
            };
            return names;
        }
};

class SMTPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SMTPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SMTPD_DROP_MAIL_PAYLOAD",
                "SMTPD_NO_CONFIGURED_SERVER"
            };
            return names;
        }
};

class SNMPGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SNMP" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SNMP_RTSLIB_FAILURE",
                "SNMP_TRAP_TRACERT_PATH_CHANGE",
                "SNMP_TRAP_TRACERT_TEST_COMPLETED",
                "SNMP_TRAP_TRACERT_TEST_FAILED"
            };
            return names;
        }
};

class SNMPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SNMPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SNMPD_AUTH_FAILURE",
                "SNMPD_AUTH_PRIVILEGES_EXCEEDED",
                "SNMPD_AUTH_RESTRICTED_ADDRESS",
                "SNMPD_AUTH_WRONG_PDU_TYPE",
                "SNMPD_BIND_INFO",
                "SNMPD_CONFIG_ERROR",
                "SNMPD_CONTEXT_ERROR",
                "SNMPD_ENGINE_ID_CHANGED",
                "SNMPD_FILE_FAILURE",
                "SNMPD_GROUP_ERROR",
                "SNMPD_HEALTH_MON_THRESH_CROSS",
                "SNMPD_INIT_FAILED",
                "SNMPD_LIBJUNIPER_FAILURE",
                "SNMPD_RADIX_FAILURE",
                "SNMPD_RECEIVE_FAILURE",
                "SNMPD_RMONFILE_FAILURE",
                "SNMPD_RMON_COOKIE",
                "SNMPD_RMON_EVENTLOG",
                "SNMPD_RMON_MIBERROR",
                "SNMPD_RTSLIB_ASYNC_EVENT",
                "SNMPD_SEND_FAILURE",
                "SNMPD_SET_FAILED",
                "SNMPD_SMOID_GEN_FAILURE",
                "SNMPD_SOCKET_FAILURE",
                "SNMPD_SOCKET_FATAL_FAILURE",
                "SNMPD_SYSLIB_FAILURE",
                "SNMPD_SYSOID_FAILURE",
                "SNMPD_SYSOID_GEN_FAILURE",
                "SNMPD_THROTTLE_QUEUE_DRAINED",
                "SNMPD_TRAP_COLD_START",
                "SNMPD_TRAP_GEN_FAILURE",
                "SNMPD_TRAP_INVALID_DATA",
                "SNMPD_TRAP_QUEUED",
                "SNMPD_TRAP_QUEUE_DRAINED",
                "SNMPD_TRAP_QUEUE_MAX_ATTEMPTS",
                "SNMPD_TRAP_QUEUE_MAX_SIZE",
                "SNMPD_TRAP_THROTTLED",
                "SNMPD_TRAP_WARM_START",
                "SNMPD_USER_ERROR"
            };
            return names;
        }
};

class SPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
               "SPD_CONFIGURATION_COMPILE",
               "SPD_CONN_FATAL_FAILURE",
               "SPD_CONN_NO_REPLY",
               "SPD_CONN_OPEN_FAILURE",
               "SPD_CONN_SEND_FAILURE",
               "SPD_CONN_UNEXPECTED_MSG",
               "SPD_DAEMONIZE_FAILED",
               "SPD_DB_IF_ADD_FAILURE",
               "SPD_DB_IF_ALLOC_FAILURE",
               "SPD_DB_SVC_SET_ADD_FAILURE",
               "SPD_DB_SVC_SET_ALLOC_FAILURE",
               "SPD_DUPLICATE",
               "SPD_EVLIB_CREATE_FAILURE",
               "SPD_EVLIB_EXIT_FAILURE",
               "SPD_GEN_NUM_FAIL",
               "SPD_NOT_ROOT",
               "SPD_OUT_OF_MEMORY",
               "SPD_PID_FILE_LOCK",
               "SPD_PID_FILE_UPDATE",
               "SPD_SERVICE_NEXT_HOP_ADD_FAILED",
               "SPD_SERVICE_NEXT_HOP_DEL_FAILED",
               "SPD_TRAP_OID_GEN_FAILED",
               "SPD_TRAP_REQUEST_FAILURE",
               "SPD_USAGE"
            };
            return names;
        }
};

class SSHGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SSH" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SSH_MSG_REPLAY_DETECT",
                "SSH_MSG_REPLAY_LIMIT",
                "SSH_RELAY_CONNECT_ERROR",
                "SSH_RELAY_USAGE"
            };
            return names;
        }
};

class SSHDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SSHD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SSHD_LOGIN_ATTEMPTS_THRESHOLD",
                "SSHD_LOGIN_FAILED",
                "SSHD_LOGIN_FAILED_LIMIT"
            };
            return names;
        }
};

class SSLGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SSL" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SSL_PROXY_ERROR",
                "SSL_PROXY_INFO",
                "SSL_PROXY_SESSION_IGNORE",
                "SSL_PROXY_SESSION_WHITELIST",
                "SSL_PROXY_SSL_SESSION_ALLOW",
                "SSL_PROXY_SSL_SESSION_DROP",
                "SSL_PROXY_WARNING"
            };
            return names;
        }
};

class SYSTEMGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "SYSTEM" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "SYSTEM_ABNORMAL_SHUTDOWN",
                "SYSTEM_OPERATIONAL",
                "SYSTEM_SHUTDOWN"
            };
            return names;
        }
};

class TFTPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "TFTPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "TFTPD_AF_ERR",
                "TFTPD_BIND_ERR",
                "TFTPD_CONNECT_ERR",
                "TFTPD_CONNECT_INFO",
                "TFTPD_CREATE_ERR",
                "TFTPD_FIO_ERR",
                "TFTPD_FORK_ERR",
                "TFTPD_NAK_ERR",
                "TFTPD_OPEN_ERR",
                "TFTPD_RECVCOMPLETE_INFO",
                "TFTPD_RECVFROM_ERR",
                "TFTPD_RECV_ERR",
                "TFTPD_SENDCOMPLETE_INFO",
                "TFTPD_SEND_ERR",
                "TFTPD_SOCKET_ERR",
                "TFTPD_STATFS_ERR"
            };
            return names;
        }
};

class UFDDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "UFDD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "UFDD_GROUP_ACTION_COMPLETE"
            };
            return names;
        }
};

class UIGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "UI" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "UI_AUTH_EVENT",
                "UI_AUTH_INVALID_CHALLENGE",
                "UI_CLI_IDLE_TIMEOUT",
                "UI_CMDLINE_READ_LINE",
                "UI_COMMIT_AT_ABORT",
                "UI_COMMIT_NOT_CONFIRMED",
                "UI_COMMIT_PREV_CNF_SAVED",
                "UI_COMMIT_ROLLBACK_FAILED",
                "UI_COND_GROUPS_COMMIT",
                "UI_COND_GROUPS_COMMIT_ABORT",
                "UI_DAEMON_ACCEPT_FAILED",
                "UI_DAEMON_FORK_FAILED",
                "UI_DAEMON_SELECT_FAILED",
                "UI_DAEMON_SOCKET_FAILED",
                "UI_FACTORY_OPERATION",
                "UI_INITIALSETUP_OPERATION",
                "UI_JUNOSCRIPT_CMD",
                "UI_LCC_NO_MASTER",
                "UI_MASTERSHIP_EVENT",
                "UI_NETCONF_CMD",
                "UI_PARSE_JUNOSCRIPT_ATTRIBUTES",
                "UI_REBOOT_EVENT",
                "UI_RESCUE_OPERATION",
                "UI_RESTART_EVENT",
                "UI_RESTART_FAILED_EVENT",
                "UI_TACPLUS_ERROR",
                "UI_WRITE_RECONNECT",
                "UI_LOGIN_EVENT",
                "UI_LOGOUT_EVENT"
            };
            return names;
        }
};

class UTMDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
          return string( "UTMD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "UTMD_MAILNOTIFIER_FAILURE",
                "UTMD_MALLOC_FAILURE",
                "UTMD_SSAMLIB_FAILURE"
            };
            return names;
        }
};

class VCCPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "VCCPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "VCCPD_KNL_VERSION",
                "VCCPD_KNL_VERSIONNONE",
                "VCCPD_KNL_VERSIONOLD",
                "VCCPD_PROTOCOL_ADJDOWN",
                "VCCPD_PROTOCOL_ADJUP",
                "VCCPD_PROTOCOL_LSPCKSUM",
                "VCCPD_PROTOCOL_OVERLOAD",
                "VCCPD_SYSTEM"
            };
            return names;
        }
};

class VMGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "VM" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "VM_DCF_PB_COMMUNICATION_FAILED",
                "VM_DCF_PB_INVALID_IMAGE",
                "VM_DCF_PB_INVALID_UUID",
                "VM_DCF_PB_RESOURCE_FAILURE"
            };
            return names;
        }
};

class VRRPDGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "VRRPD" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "VRRPD_ADVERT_TIME_MISMATCH",
                "VRRPD_AUTH_INFO_INVALID",
                "VRRPD_GET_TRAP_HEADER_FAILED",
                "VRRPD_LINK_LOCAL_ADD_MISMATCH",
                "VRRPD_MISSING_VIP",
                "VRRPD_NEW_BACKUP",
                "VRRPD_NEW_MASTER",
                "VRRPD_VIP_COUNT_MISMATCH"
            };
            return names;
        }
};

class WEBGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "WEB" );
        }

        vector<string>& GetFacilityNames()
        {
              static vector<string> names =
              {
                  "WEB_AUTH_FAIL",
                  "WEB_AUTH_SUCCESS",
                  "WEB_AUTH_TIME_EXCEEDED",
                  "WEB_CERT_FILE_NOT_FOUND",
                  "WEB_CHILD_STATE",
                  "WEB_CONFIG_OPEN_ERROR",
                  "WEB_CONFIG_WRITE_ERROR",
                  "WEB_COULDNT_START_HTTPD",
                  "WEB_EVENTLIB_INIT",
                  "WEB_KEYPAIR_FILE_NOT_FOUND",
                  "WEB_MGD_BIND_ERROR",
                  "WEB_MGD_CHMOD_ERROR",
                  "WEB_MGD_CONNECT_ERROR",
                  "WEB_MGD_FCNTL_ERROR",
                  "WEB_MGD_LISTEN_ERROR",
                  "WEB_MGD_RECVMSG_PEEK_ERROR",
                  "WEB_MGD_SOCKET_ERROR",
                  "WEB_PIDFILE_LOCK",
                  "WEB_PIDFILE_UPDATE",
                  "WEB_UNAME_FAILED",
                  "WEB_WEBAUTH_AUTH_FAIL",
                  "WEB_WEBAUTH_AUTH_OK",
                  "WEB_WEBAUTH_CONNECT_FAIL"
              };
              return names;
        }
};

class WEBFILTERGroup : public IJunosFacilityGroup
{
    public:
        string GetGroupName()
        {
            return string( "WEBFILTER" );
        }

        vector<string>& GetFacilityNames()
        {
            static vector<string> names =
            {
                "WEBFILTER_CACHE_NOT_ENABLED",
                "WEBFILTER_INTERNAL_ERROR",
                "WEBFILTER_REQUEST_NOT_CHECKED",
                "WEBFILTER_SERVER_CONNECTED",
                "WEBFILTER_SERVER_DISCONNECTED",
                "WEBFILTER_SERVER_ERROR",
                "WEBFILTER_URL_BLOCKED",
                "WEBFILTER_URL_PERMITTED",
                "WEBFILTER_URL_REDIRECTED"
            };
            return names;
        }
};

JunosFacilityGroups::JunosFacilityGroups( ):
m_GroupNameMaxLenght( 0 )
{
    m_Groups.push_back( shared_ptr<RTGroup>( new RTGroup( )) );
    m_Groups.push_back( shared_ptr<ACCTGroup>( new ACCTGroup( )) );
    m_Groups.push_back( shared_ptr<ALARMDGroup>( new ALARMDGroup( )) );
    m_Groups.push_back( shared_ptr<ANALYZERGroup>( new ANALYZERGroup( )) );
    m_Groups.push_back( shared_ptr<ANCPDGroup>( new ANCPDGroup( )) );
    m_Groups.push_back( shared_ptr<APPIDGroup>( new APPIDGroup( )) );
    m_Groups.push_back( shared_ptr<APPIDDGroup>( new APPIDDGroup( )) );
    m_Groups.push_back( shared_ptr<APPTRACKGroup>( new APPTRACKGroup( )) );
    m_Groups.push_back( shared_ptr<ASPGroup>( new ASPGroup( )) );
    m_Groups.push_back( shared_ptr<AUDITDGroup>( new AUDITDGroup( )) );
    m_Groups.push_back( shared_ptr<AUTHDGroup>( new AUTHDGroup( )) );
    m_Groups.push_back( shared_ptr<AUTOCONFDGroup>( new AUTOCONFDGroup( )) );
    m_Groups.push_back( shared_ptr<AUTODGroup>( new AUTODGroup( )) );
    m_Groups.push_back( shared_ptr<AVGroup>( new AVGroup( )) );
    m_Groups.push_back( shared_ptr<BFDDGroup>( new BFDDGroup( )) );
    m_Groups.push_back( shared_ptr<Group>( new Group( )) );
    m_Groups.push_back( shared_ptr<CFMDGroup>( new CFMDGroup( )) );
    m_Groups.push_back( shared_ptr<CHASSISDGroup>( new CHASSISDGroup( )) );
    m_Groups.push_back( shared_ptr<CHASSISMGroup>( new CHASSISMGroup( )) );
    m_Groups.push_back( shared_ptr<COSDGroup>( new COSDGroup( )) );
    m_Groups.push_back( shared_ptr<DCBXGroup>( new DCBXGroup( )) );
    m_Groups.push_back( shared_ptr<DCDGroup>( new DCDGroup( )) );
    m_Groups.push_back( shared_ptr<DDOSGroup>( new DDOSGroup( )) );
    m_Groups.push_back( shared_ptr<DFCDGroup>( new DFCDGroup( )) );
    m_Groups.push_back( shared_ptr<DFWDGroup>( new DFWDGroup( )) );
    m_Groups.push_back( shared_ptr<DHCPDGroup>( new DHCPDGroup( )) );
    m_Groups.push_back( shared_ptr<DOT1XDGroup>( new DOT1XDGroup( )) );
    m_Groups.push_back( shared_ptr<DYNAMICGroup>( new DYNAMICGroup( )) );
    m_Groups.push_back( shared_ptr<ESWDGroup>( new ESWDGroup( )) );
    m_Groups.push_back( shared_ptr<EVENTDGroup>( new EVENTDGroup( )) );
    m_Groups.push_back( shared_ptr<FABOAMDGroup>( new FABOAMDGroup( )) );
    m_Groups.push_back( shared_ptr<FCGroup>( new FCGroup( )) );
    m_Groups.push_back( shared_ptr<FCOEGroup>( new FCOEGroup( )) );
    m_Groups.push_back( shared_ptr<FIPGroup>( new FIPGroup( )) );
    m_Groups.push_back( shared_ptr<FIPSGroup>( new FIPSGroup( )) );
    m_Groups.push_back( shared_ptr<FLOWGroup>( new FLOWGroup( )) );
    m_Groups.push_back( shared_ptr<FPCLOGINGroup>( new FPCLOGINGroup( )) );
    m_Groups.push_back( shared_ptr<FSADGroup>( new FSADGroup( )) );
    m_Groups.push_back( shared_ptr<FUDGroup>( new FUDGroup( )) );
    m_Groups.push_back( shared_ptr<FWAUTHGroup>( new FWAUTHGroup( )) );
    m_Groups.push_back( shared_ptr<GPRSDGroup>( new GPRSDGroup( )) );
    m_Groups.push_back( shared_ptr<HNCACHEDGroup>( new HNCACHEDGroup( )) );
    m_Groups.push_back( shared_ptr<ICCPDGroup>( new ICCPDGroup( )) );
    m_Groups.push_back( shared_ptr<IDPGroup>( new IDPGroup( )) );
    m_Groups.push_back( shared_ptr<JADEGroup>( new JADEGroup( )) );
    m_Groups.push_back( shared_ptr<JCSGroup>( new JCSGroup( )) );
    m_Groups.push_back( shared_ptr<JDIAMETERDGroup>( new JDIAMETERDGroup( )) );
    m_Groups.push_back( shared_ptr<JIVEDGroup>( new JIVEDGroup( )) );
    m_Groups.push_back( shared_ptr<JPTSPDGroup>( new JPTSPDGroup( )) );
    m_Groups.push_back( shared_ptr<JSRPDGroup>( new JSRPDGroup( )) );
    m_Groups.push_back( shared_ptr<JTASKGroup>( new JTASKGroup( )) );
    m_Groups.push_back( shared_ptr<JTRACEGroup>( new JTRACEGroup( )) );
    m_Groups.push_back( shared_ptr<KMDGroup>( new KMDGroup( )) );
    m_Groups.push_back( shared_ptr<L2ALDGroup>( new L2ALDGroup( )) );
    m_Groups.push_back( shared_ptr<L2CPDGroup>( new L2CPDGroup( )) );
    m_Groups.push_back( shared_ptr<L2TPDGroup>( new L2TPDGroup( )) );
    m_Groups.push_back( shared_ptr<LACPGroup>( new LACPGroup( )) );
    m_Groups.push_back( shared_ptr<LACPDGroup>( new LACPDGroup( )) );
    m_Groups.push_back( shared_ptr<LFMDGroup>( new LFMDGroup( )) );
    m_Groups.push_back( shared_ptr<LIBJNXGroup>( new LIBJNXGroup( )) );
    m_Groups.push_back( shared_ptr<LIBJSNMPGroup>( new LIBJSNMPGroup( )) );
    m_Groups.push_back( shared_ptr<LIBMSPRPCGroup>( new LIBMSPRPCGroup( )) );
    m_Groups.push_back( shared_ptr<LICENSEGroup>( new LICENSEGroup( )) );
    m_Groups.push_back( shared_ptr<LOGINGroup>( new LOGINGroup( )) );
    m_Groups.push_back( shared_ptr<LPDFDGroup>( new LPDFDGroup( )) );
    m_Groups.push_back( shared_ptr<LRMUXGroup>( new LRMUXGroup( )) );
    m_Groups.push_back( shared_ptr<LSYSDGroup>( new LSYSDGroup( )) );
    m_Groups.push_back( shared_ptr<MCSNGroup>( new MCSNGroup( )) );
    m_Groups.push_back( shared_ptr<MCSNOOPDGroup>( new MCSNOOPDGroup( )) );
    m_Groups.push_back( shared_ptr<MIB2DGroup>( new MIB2DGroup( )) );
    m_Groups.push_back( shared_ptr<MPLS_OAMGroup>( new MPLS_OAMGroup( )) );
    m_Groups.push_back( shared_ptr<NEXTHOPGroup>( new NEXTHOPGroup( )) );
    m_Groups.push_back( shared_ptr<NSDGroup>( new NSDGroup( )) );
    m_Groups.push_back( shared_ptr<NSTRACEDGroup>( new NSTRACEDGroup( )) );
    m_Groups.push_back( shared_ptr<NTPDATEGroup>( new NTPDATEGroup( )) );
    m_Groups.push_back( shared_ptr<NTPDGroup>( new NTPDGroup( )) );
    m_Groups.push_back( shared_ptr<PFEGroup>( new PFEGroup( )) );
    m_Groups.push_back( shared_ptr<PFEDGroup>( new PFEDGroup( )) );
    m_Groups.push_back( shared_ptr<PGCPDGroup>( new PGCPDGroup( )) );
    m_Groups.push_back( shared_ptr<PINGGroup>( new PINGGroup( )) );
    m_Groups.push_back( shared_ptr<PKIDGroup>( new PKIDGroup( )) );
    m_Groups.push_back( shared_ptr<PPMDGroup>( new PPMDGroup( )) );
    m_Groups.push_back( shared_ptr<PPPDGroup>( new PPPDGroup( )) );
    m_Groups.push_back( shared_ptr<PROFILERGroup>( new PROFILERGroup( )) );
    m_Groups.push_back( shared_ptr<RDDGroup>( new RDDGroup( )) );
    m_Groups.push_back( shared_ptr<RMOPDGroup>( new RMOPDGroup( )) );
    m_Groups.push_back( shared_ptr<RPDGroup>( new RPDGroup( )) );
    m_Groups.push_back( shared_ptr<RTLOGGroup>( new RTLOGGroup( )) );
    m_Groups.push_back( shared_ptr<RTLOGDGroup>( new RTLOGDGroup( )) );
    m_Groups.push_back( shared_ptr<RTPERFGroup>( new RTPERFGroup( )) );
    m_Groups.push_back( shared_ptr<SAVALGroup>( new SAVALGroup( )) );
    m_Groups.push_back( shared_ptr<SDXDGroup>( new SDXDGroup( )) );
    m_Groups.push_back( shared_ptr<SFWGroup>( new SFWGroup( )) );
    m_Groups.push_back( shared_ptr<SMTPDGroup>( new SMTPDGroup( )) );
    m_Groups.push_back( shared_ptr<SNMPGroup>( new SNMPGroup( )) );
    m_Groups.push_back( shared_ptr<SNMPDGroup>( new SNMPDGroup( )) );
    m_Groups.push_back( shared_ptr<SPDGroup>( new SPDGroup( )) );
    m_Groups.push_back( shared_ptr<SSHGroup>( new SSHGroup( )) );
    m_Groups.push_back( shared_ptr<SSHDGroup>( new SSHDGroup( )) );
    m_Groups.push_back( shared_ptr<SSLGroup>( new SSLGroup( )) );
    m_Groups.push_back( shared_ptr<SYSTEMGroup>( new SYSTEMGroup( )) );
    m_Groups.push_back( shared_ptr<TFTPDGroup>( new TFTPDGroup( )) );
    m_Groups.push_back( shared_ptr<UFDDGroup>( new UFDDGroup( )) );
    m_Groups.push_back( shared_ptr<UIGroup>( new UIGroup( )) );
    m_Groups.push_back( shared_ptr<UTMDGroup>( new UTMDGroup( )) );
    m_Groups.push_back( shared_ptr<VCCPDGroup>( new VCCPDGroup( )) );
    m_Groups.push_back( shared_ptr<VMGroup>( new VMGroup( )) );
    m_Groups.push_back( shared_ptr<VRRPDGroup>( new VRRPDGroup( )) );
    m_Groups.push_back( shared_ptr<WEBGroup>( new WEBGroup( )) );
    m_Groups.push_back( shared_ptr<WEBFILTERGroup>( new WEBFILTERGroup( )) );

    for( auto gpoup : m_Groups )
    {
        for( string& memberName : gpoup->GetFacilityNames( ) )
        {
            m_GroupNameMaxLenght = max( m_GroupNameMaxLenght, memberName.size( ) );
        }
    }
}

size_t JunosFacilityGroups::GetGroupNameMaxLenght( )
{
    return m_GroupNameMaxLenght;
}

vector< shared_ptr<IJunosFacilityGroup> >& JunosFacilityGroups::GetGroups( )
{
    return m_Groups;
}
