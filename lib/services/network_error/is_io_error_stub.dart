/// Web build: `dart:io` isn't available, and the browser surfaces transport
/// failures as `http.ClientException`, which [userFacingError] already covers.
bool isIoError(Object error) => false;
