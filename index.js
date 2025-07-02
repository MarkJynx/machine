let x = document.createElement("pre")
x.textContent = "Hello World"

fetch("http://127.0.0.1/cgi-bin/hello", {method:"POST"}).then(function(response) {
  return response.text();
}).then(function(data) {
  console.log(data);
}).catch(function(err) {
  console.log('Fetch Error :-S', err);
});


document.body.appendChild(x)
