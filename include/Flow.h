/*
 *
 * (C) 2013-16 - ntop.org
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 */

#ifndef _FLOW_H_
#define _FLOW_H_

#include "ntop_includes.h"

typedef struct {
  u_int32_t pktRetr, pktOOO, pktLost;
  u_int64_t last, next;
} TCPPacketStats;

typedef struct {
  struct timeval lastTime;
  u_int64_t total_delta_ms;
  float min_ms, max_ms;
} InterarrivalStats;

typedef struct {
  InterarrivalStats pktTime;
} FlowPacketStats;

class Flow : public GenericHashEntry {
 private:
  Host *cli_host, *srv_host;
  u_int16_t cli_port, srv_port;
  u_int16_t vlanId;
  u_int8_t protocol, src2dst_tcp_flags, dst2src_tcp_flags;
  struct ndpi_flow_struct *ndpiFlow;
  bool detection_completed, protocol_processed, blacklist_alarm_emitted,
    cli2srv_direction, twh_over, dissect_next_http_packet, passVerdict,
    ssl_flow_without_certificate_name, check_tor, l7_protocol_guessed,
    good_low_flow_detected;
  u_int16_t diff_num_http_requests;
#ifdef NTOPNG_PRO
  FlowProfile *trafficProfile;
  CounterTrend throughputTrend, goodputTrend, thptRatioTrend;
#endif
  ndpi_protocol ndpiDetectedProtocol;
  void *cli_id, *srv_id;
  char *json_info, *host_server_name, *ndpi_proto_name, *bt_hash;
  bool dump_flow_traffic, badFlow;

  struct {
    char *last_url, *last_method;
    u_int16_t last_return_code;
  } http;

  struct {
    char *last_query;
  } dns;

  struct {
    char *certificate;
  } ssl;

  struct {
    struct site_categories category;
    bool categorized_requested;
  } categorization;

  /* Process Information */
  ProcessInfo *client_proc, *server_proc;

  /* Stats */
  u_int32_t cli2srv_packets, srv2cli_packets;
  u_int64_t cli2srv_bytes, srv2cli_bytes;
  /* https://en.wikipedia.org/wiki/Goodput */
  u_int64_t cli2srv_goodput_bytes, srv2cli_goodput_bytes;

  /* TCP stats */
  TCPPacketStats tcp_stats_s2d, tcp_stats_d2s;
  u_int16_t cli2srv_window, srv2cli_window;

  time_t doNotExpireBefore; /*
			       Used for collected flows via ZMQ to make sure that they are not immediately
			       expired if their last seen time is back in time with respect to ntopng
			    */

  struct timeval synTime, synAckTime, ackTime; /* network Latency (3-way handshake) */
  struct timeval clientNwLatency; /* The RTT/2 between the client and nprobe */
  struct timeval serverNwLatency; /* The RTT/2 between nprobe and the server */
  float rttSec;

  FlowPacketStats cli2srvStats, srv2cliStats;

  /* Counter values at last host update */
  struct {
    u_int32_t cli2srv_packets, srv2cli_packets;
    u_int64_t cli2srv_bytes, srv2cli_bytes;
    u_int64_t cli2srv_goodput_bytes, srv2cli_goodput_bytes;
    u_int32_t last_dump;
  } last_db_dump;

  struct timeval last_update_time;

  float bytes_thpt, goodput_bytes_thpt, top_bytes_thpt, top_goodput_bytes_thpt, top_pkts_thpt;
  float bytes_thpt_cli2srv, goodput_bytes_thpt_cli2srv;
  float bytes_thpt_srv2cli, goodput_bytes_thpt_srv2cli;
  float pkts_thpt, pkts_thpt_cli2srv, pkts_thpt_srv2cli;
  ValueTrend bytes_thpt_trend, goodput_bytes_thpt_trend, pkts_thpt_trend;
  //TimeSeries<float> *bytes_rate;
  u_int64_t cli2srv_last_packets, srv2cli_last_packets,
    prev_cli2srv_last_packets, prev_srv2cli_last_packets;
  u_int64_t cli2srv_last_bytes, srv2cli_last_bytes,
    cli2srv_last_goodput_bytes, srv2cli_last_goodput_bytes,
    prev_cli2srv_last_bytes, prev_srv2cli_last_bytes,
    prev_cli2srv_last_goodput_bytes, prev_srv2cli_last_goodput_bytes;

  //  tcpFlags = tp->th_flags, tcpSeqNum = ntohl(tp->th_seq), tcpAckNum = ntohl(tp->th_ack), tcpWin = ntohs(tp->th_win);
  char* intoaV4(unsigned int addr, char* buf, u_short bufLen);
  void processLua(lua_State* vm, ProcessInfo *proc, bool client);
  void processJson(bool is_src, json_object *my_object, ProcessInfo *proc);
  void checkBlacklistedFlow();
  void allocFlowMemory();
  bool checkTor(char *hostname);
  void checkFlowCategory();
  void setBittorrentHash(char *hash);
  bool isLowGoodput();
  void updatePacketStats(InterarrivalStats *stats, const struct timeval *when);
  void dumpPacketStats(lua_State* vm, bool cli2srv_direction);

 public:
  Flow(NetworkInterface *_iface,
       u_int16_t _vlanId, u_int8_t _protocol,
       u_int8_t cli_mac[6], IpAddress *_cli_ip, u_int16_t _cli_port,
       u_int8_t srv_mac[6], IpAddress *_srv_ip, u_int16_t _srv_port,
       time_t _first_seen, time_t _last_seen);
  ~Flow();

  struct site_categories* getFlowCategory(bool force_categorization);
  void categorizeFlow();
  void deleteFlowMemory();
  char* serialize(bool partial_dump = false, bool es_json = false);
  json_object* flow2json(bool partial_dump);
  json_object* flow2es(json_object *flow_object);
  inline u_int8_t getTcpFlags() { return(src2dst_tcp_flags | dst2src_tcp_flags);  };
  bool isPassVerdict();
  void setDropVerdict()         { passVerdict = false; };
  u_int32_t getPid(bool client);
  u_int32_t getFatherPid(bool client);
  char* get_username(bool client);
  char* get_proc_name(bool client);
  u_int32_t getNextTcpSeq(u_int8_t tcpFlags, u_int32_t tcpSeqNum, u_int32_t payloadLen) ;
  void makeVerdict(bool reset);
  double toMs(const struct timeval *t);
  void timeval_diff(struct timeval *begin, const struct timeval *end, struct timeval *result, u_short divide_by_two);
  inline char* getFlowServerInfo() { return(host_server_name); };
  inline char* getBitTorrentHash() { return(bt_hash);          };
  inline void  setServerName(char *v)  { if(host_server_name) free(host_server_name);  host_server_name = strdup(v); }
  void updateTcpFlags(const struct bpf_timeval *when,
		      u_int8_t flags, bool src2dst_direction);

  void updateTcpSeqNum(const struct bpf_timeval *when,
		       u_int32_t seq_num, u_int32_t ack_seq_num,
		       u_int16_t window, u_int8_t flags,
		       u_int16_t payload_len, bool src2dst_direction);

  void updateSeqNum(time_t when, u_int32_t sN, u_int32_t aN);
  void processDetectedProtocol();
  void setDetectedProtocol(ndpi_protocol proto_id);
  void setJSONInfo(const char *json);
  bool isFlowPeer(char *numIP, u_int16_t vlanId);
  void incStats(bool cli2srv_direction, u_int pkt_len,
		u_int payload_len, const struct bpf_timeval *when);
  void updateActivities();
  void addFlowStats(bool cli2srv_direction, u_int in_pkts, u_int in_bytes, u_int in_goodput_bytes,
		    u_int out_pkts, u_int out_bytes, u_int out_goodput_bytes, time_t last_seen);
  inline bool isDetectionCompleted()              { return(detection_completed);             };
  inline struct ndpi_flow_struct* get_ndpi_flow() { return(ndpiFlow);                        };
  inline void* get_cli_id()                       { return(cli_id);                          };
  inline void* get_srv_id()                       { return(srv_id);                          };
  inline u_int32_t get_cli_ipv4()                 { return(cli_host->get_ip()->get_ipv4());  };
  inline u_int32_t get_srv_ipv4()                 { return(srv_host->get_ip()->get_ipv4());  };
  inline u_int16_t get_cli_port()                 { return(ntohs(cli_port));                 };
  inline u_int16_t get_srv_port()                 { return(ntohs(srv_port));                 };
  inline u_int16_t get_vlan_id()                  { return(vlanId);                          };
  inline u_int8_t  get_protocol()                 { return(protocol);                        };
  inline u_int64_t get_bytes()                    { return(cli2srv_bytes+srv2cli_bytes);     };
  inline u_int64_t get_goodput_bytes()            { return(cli2srv_goodput_bytes+srv2cli_goodput_bytes);     };
  inline u_int64_t get_packets()                  { return(cli2srv_packets+srv2cli_packets); };
  inline u_int64_t get_partial_bytes()            { return(get_bytes() - (last_db_dump.cli2srv_bytes+last_db_dump.srv2cli_bytes));       };
  inline u_int64_t get_partial_goodput_bytes()    { return(get_goodput_bytes() - (last_db_dump.cli2srv_goodput_bytes+last_db_dump.srv2cli_goodput_bytes));       };
  inline u_int64_t get_partial_packets()          { return(get_packets() - (last_db_dump.cli2srv_packets+last_db_dump.srv2cli_packets)); };
  inline float get_bytes_thpt()                   { return(bytes_thpt);                      };
  inline float get_goodput_bytes_thpt()           { return(goodput_bytes_thpt);              };

  inline time_t get_partial_first_seen()          { return(last_db_dump.last_dump == 0 ? get_first_seen() : last_db_dump.last_dump); };
  inline time_t get_partial_last_seen()           { return(get_last_seen()); };
  inline u_int32_t get_duration()                 { return((u_int32_t)(get_last_seen()-get_first_seen())); };
  inline char* get_protocol_name()                { return(Utils::l4proto2name(protocol));   };
  inline ndpi_protocol get_detected_protocol()    { return(ndpiDetectedProtocol);          };
  inline Host* get_cli_host()                     { return(cli_host);                        };
  inline Host* get_srv_host()                     { return(srv_host);                        };
  inline char* get_json_info()			  { return(json_info);                       };
  inline ndpi_protocol_breed_t get_protocol_breed() { return(ndpi_get_proto_breed(iface->get_ndpi_struct(), ndpiDetectedProtocol.protocol)); };
  inline char* get_protocol_breed_name()            { return(ndpi_get_proto_breed_name(iface->get_ndpi_struct(),
										       ndpi_get_proto_breed(iface->get_ndpi_struct(),
													    ndpiDetectedProtocol.protocol))); };
  char* get_detected_protocol_name();
  u_int32_t get_packetsLost();
  u_int32_t get_packetsRetr();
  u_int32_t get_packetsOOO();

  u_int64_t get_current_bytes_cli2srv();
  u_int64_t get_current_bytes_srv2cli();
  u_int64_t get_current_goodput_bytes_cli2srv();
  u_int64_t get_current_goodput_bytes_srv2cli();
  u_int64_t get_current_packets_cli2srv();
  u_int64_t get_current_packets_srv2cli();
  void handle_process(ProcessInfo *pinfo, bool client_process);
  bool idle();
  int compare(Flow *fb);
  inline bool is_l7_protocol_guessed() { return(l7_protocol_guessed); };
  char* print(char *buf, u_int buf_len);
  void update_hosts_stats(struct timeval *tv);
  void print_peers(lua_State* vm, patricia_tree_t * ptree, bool verbose);
  u_int32_t key();
  void lua(lua_State* vm, patricia_tree_t * ptree, bool detailed_dump, bool asListElement);
  bool equal(IpAddress *_cli_ip, IpAddress *_srv_ip,
	     u_int16_t _cli_port, u_int16_t _srv_port,
	     u_int16_t _vlanId, u_int8_t _protocol,
	     bool *src2srv_direction);
  void sumStats(nDPIStats *stats);
  void guessProtocol();
  bool dumpFlow(bool partial_dump);
  bool dumpFlowTraffic(void);
  bool match(patricia_tree_t *ptree);
  inline Host* get_real_client() { return(cli2srv_direction ? cli_host : srv_host); }
  inline Host* get_real_server() { return(cli2srv_direction ? srv_host : cli_host); }
  inline bool isBadFlow()        { return(badFlow); }
  inline bool isSuspiciousFlowThpt();
  void dissectHTTP(bool src2dst_direction, char *payload, u_int16_t payload_len);
  void dissectBittorrent(char *payload, u_int16_t payload_len);
  void updateInterfaceStats(bool src2dst_direction, u_int num_pkts, u_int pkt_len);
  inline char* getDNSQuery()        { return(dns.last_query);  }
  inline void  setDNSQuery(char *v) { if(dns.last_query) free(dns.last_query);  dns.last_query = strdup(v); }
  inline char* getHTTPURL()         { return(http.last_url);   }
  inline void  setHTTPURL(char *v)  { if(http.last_url) free(http.last_url);  http.last_url = strdup(v); }
  inline char* getSSLCertificate()  { return(ssl.certificate); }
  void setDumpFlowTraffic(bool what)  { dump_flow_traffic = what; }
  bool getDumpFlowTraffic(void)       { return dump_flow_traffic; }
  void getFlowShapers(bool src2dst_direction, int *a_shaper_id, int *b_shaper_id, u_int16_t *ndpiProtocol);
#ifdef NTOPNG_PRO
  inline void updateProfile()   { trafficProfile = iface->getFlowProfile(this); }
  inline char* get_profile_name() { return(trafficProfile ? trafficProfile->getName() : (char*)"");}
#endif
  inline float getFlowRTT() { return(rttSec); }
  /* http://bradhedlund.com/2008/12/19/how-to-calculate-tcp-throughput-for-long-distance-links/ */
  inline float getCli2SrvMaxThpt() { return(rttSec ? ((float)(cli2srv_window*8)/rttSec) : 0); }
  inline float getSrv2CliMaxThpt() { return(rttSec ? ((float)(srv2cli_window*8)/rttSec) : 0); }

  inline u_int32_t getCli2SrvMinInterArrivalTime() { return(cli2srvStats.pktTime.min_ms); }
  inline u_int32_t getCli2SrvMaxInterArrivalTime() { return(cli2srvStats.pktTime.max_ms); }
  inline u_int32_t getCli2SrvAvgInterArrivalTime() { return((cli2srv_packets < 2) ? 0 : cli2srvStats.pktTime.total_delta_ms / (cli2srv_packets-1)); }
  inline u_int32_t getSrv2CliMinInterArrivalTime() { return(srv2cliStats.pktTime.min_ms); }
  inline u_int32_t getSrv2CliMaxInterArrivalTime() { return(srv2cliStats.pktTime.max_ms); }
  inline u_int32_t getSrv2CliAvgInterArrivalTime() { return((srv2cli_packets < 2) ? 0 : srv2cliStats.pktTime.total_delta_ms / (srv2cli_packets-1)); }
};

#endif /* _FLOW_H_ */
