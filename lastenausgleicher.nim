import
    strformat,
    tables,
    json,
    strutils,
    sequtils,
    hashes, 
    net,
    asyncdispatch,
    asyncnet,
    os,
    strutils,
    parseutils,
    deques,
    options,
    net,
    parseopt

type 
    LoadBalancingEndpoint = object
        listenAddr*: string
        listenPort*: Port

type
    Forwarder = object of RootObj
        endpoint*: LoadBalancingEndpoint

var 
    loadBalancingEndpoints: seq[LoadBalancingEndpoint]
    hosts: seq[string]
    hostWithPort: seq[string]

var p = initOptParser()
while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
        if p.key == "h" or p.key == "hosts":
            if p.val.isEmptyOrWhitespace:
                echo "-h/--hosts needs a comma separated list of hosts"
                quit(-1)

            hosts = p.val.split(',')
        else:
            echo "unknown commandline option"
    of cmdArgument:
        echo "pwerifiwoeh"

for host in hosts:
    hostWithPort = host.split(':')

    if hostWithPort.len == 1:
        hostWithPort.add("80")

    loadBalancingEndpoints.add(LoadBalancingEndpoint(listenAddr: hostWithPort[0], listenPort: parseInt(hostWithPort[1]).Port))

    echo "Added endpoint ", hostWithPort[0], " -> ", hostWithPort[1]


