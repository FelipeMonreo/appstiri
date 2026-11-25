"""Serve the existing Flutter web build on the home network for phone testing."""

from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from ipaddress import ip_address
from pathlib import Path
import socket


def main():
    build = Path(__file__).resolve().parent.parent / "build" / "web"
    if not (build / "index.html").is_file():
        print("Lipseste buildul web. Aplicatia trebuie compilata inainte de pornire.")
        return

    port = 5175
    handler = partial(SimpleHTTPRequestHandler, directory=str(build))
    try:
        server = ThreadingHTTPServer(("0.0.0.0", port), handler)
    except OSError as error:
        print(f"Nu pot porni serverul pe portul {port}: {error}")
        print("Daca aplicatia este deja pornita, foloseste adresa afisata anterior.")
        return

    print("\nConecteaza iPhone-ul si calculatorul la aceeasi retea Wi-Fi.")
    print("Serverul trebuie pornit din File Explorer, cu Porneste-iPhone.cmd.")
    print("Deschide in Safari una dintre adresele calculatorului:")
    addresses = set()
    try:
        for entry in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            address = entry[4][0]
            parsed = ip_address(address)
            if parsed.is_private and not parsed.is_loopback and not parsed.is_link_local:
                addresses.add(address)
    except OSError:
        pass
    for address in sorted(addresses):
        print(f"    http://{address}:{port}")
    if not addresses:
        print(f"    http://ADRESA_IP_A_CALCULATORULUI:{port}")
        print("Adresa IPv4 se gaseste in Setari Windows > Retea si internet > Wi-Fi > Proprietati.")
    print("\nPastreaza aceasta fereastra deschisa. Pentru oprire: Ctrl+C.")
    print("Daca Windows solicita acces pentru Python, permite accesul pe reteaua privata.")
    print("Browserul permite testarea interfetei si exportul .ics.")
    print("Salvarea directa in calendar necesita aplicatia iOS instalata.\n", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer oprit.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
