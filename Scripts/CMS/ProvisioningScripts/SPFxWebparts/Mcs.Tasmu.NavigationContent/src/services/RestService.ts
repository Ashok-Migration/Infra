declare var fetch: any;
export class RestService {

    public static Get(url: string, verbose = false) {
        var promise = new Promise((resolve, reject) => {
            fetch(url, {
                credentials: 'same-origin',
                headers: {
                    'Accept': 'application/json;odata=' + (verbose ? 'verbose' : 'nometadata')
                }
            }).then((rawResponse) => {
                if (rawResponse.ok) {
                    rawResponse.json().then((response: any) => {
                        try {
                            if (response.value) {
                                resolve(response.value);
                            }
                            else if (response.d.results) {
                                resolve(response.d.results);
                            }
                            else {
                                resolve(response);
                            }
                        }
                        catch (e) {
                            resolve(response);
                        }
                    }).catch((ex) => {
                        reject(ex);
                    });
                }
                else {
                    reject(`${rawResponse.status} - ${rawResponse.statusText}`);
                }
            }).catch((ex) => {
                reject(ex);
            });
        });

        return promise;
    }

    public static PostWithHeader(url: string, headers, data) {
        var promise = new Promise((resolve, reject) => {
            fetch(url, {
                method: "post",
                headers: headers,
                body: data
            }).then((rawResponse) => {
                if (rawResponse.ok) {
                    rawResponse.json().then((response: any) => {
                        resolve(response);
                    }).catch((ex) => {
                        reject(ex);
                    });
                }
                else {
                    reject(`${rawResponse.status} - ${rawResponse.statusText}`);
                }
            }).catch((ex) => {
                reject(ex);
            });
        });

        return promise;
    }

    public static Post(url, data) {
        var itemExists = false;

        if (data.ID) {
            itemExists = true;
        }

        var headers = {
            'Accept': 'application/json;odata=verbose',
            'Content-Type': 'application/json;odata=verbose',
            'X-RequestDigest': (document.getElementById('__REQUESTDIGEST') as HTMLInputElement).value
        };

        if (itemExists) {
            url += `(${data.ID})`;
            headers["X-HTTP-Method"] = "MERGE";
            headers["If-Match"] = "*";
        }

        var promise = new Promise((resolve, reject) => {
            fetch(`${url}`, {
                method: 'post',
                credentials: 'same-origin',
                headers: headers,
                body: JSON.stringify(data)
            }).then((response) => {
                if (response.ok) {
                    resolve(data);
                }
                else {
                    reject(`${response.status} - ${response.statusText}`);
                }
            }).catch((ex) => {
                reject(ex);
            });
        });

        return promise;
    }

    public static GetWithHeader(url: string, headers) {
        var promise = new Promise((resolve, reject) => {
            fetch(url, {
                headers: headers
            }).then((rawResponse) => {
                if (rawResponse.ok) {
                    rawResponse.json().then((response: any) => {
                        resolve(response);
                    }).catch((ex) => {
                        reject(ex);
                    });
                }
                else {
                    reject(`${rawResponse.status} - ${rawResponse.statusText}`);
                }
            }).catch((ex) => {
                reject(ex);
            });
        });

        return promise;
    }
}

