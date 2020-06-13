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
        address*: string
        port*: Port

type
    Forwarder = object of RootObj
        endpoint*: LoadBalancingEndpoint

var 
    loadBalancingEndpoints: seq[LoadBalancingEndpoint]
    hosts: seq[string]
    hostWithPort: seq[string]

proc processClient(this: ref Forwarder, client: AsyncSocket) {.async.} =
    let remote = newAsyncSocket(buffered=false)
    await remote.connect(this.endpoint.address, this.endpoint.port)

    proc clientHasData() {.async.} =
        while not client.isClosed and not remote.isClosed:
            let data = await client.recv(1024)
            await remote.send(data)
        client.close()
        remote.close()

    proc remoteHasData() {.async.} =
        while not remote.isClosed and not client.isClosed:
            let data = await remote.recv(1024)
            await client.send(data)
        client.close()
        remote.close()

    try:
        asyncCheck clientHasData()
        asyncCheck remoteHasData()
    except:
        echo getCurrentExceptionMsg()

proc serve(this: ref Forwarder) {.async.} =
    var server = newAsyncSocket(buffered=false)
    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(1337.Port, "127.0.0.1")
    echo fmt"Started tcp server..."
    server.listen()

    while true:
        let client = await server.accept()
        echo "..Got connection "

        asyncCheck this.processClient(client)

proc newForwarder(endpoint: LoadBalancingEndpoint): ref Forwarder =
    result = new(Forwarder)
    result.endpoint = endpoint

# main
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

    loadBalancingEndpoints.add(LoadBalancingEndpoint(address: hostWithPort[0], port: parseInt(hostWithPort[1]).Port))

    echo "Added endpoint ", hostWithPort[0], " -> ", hostWithPort[1]


var f = newForwarder(loadBalancingEndpoints[0])
asyncCheck f.serve()
runForever()