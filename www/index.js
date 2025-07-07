let x = document.createElement("pre")
x.textContent = "Hello World"

//fetch("http://127.0.0.1/cgi-bin/hello.lua", {method:"POST", body: JSON.stringify({ username: "example" })}).then(function(response) {
fetch("http://127.0.0.1/cgi-bin/hello.lua", {method:"POST", body: "hello"}).then(function(response) {
//fetch("http://127.0.0.1/cgi-bin/hello.lua", {method:"POST"}).then(function(response) {
  return response.text();
}).then(function(data) {
  console.log(data);
}).catch(function(err) {
  console.log('Fetch Error :-S', err);
});


document.body.appendChild(x)
