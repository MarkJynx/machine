let x = document.createElement("pre")
x.textContent = "Hello World"

fetch("http://127.0.0.1/hello").then(function(response) {
  return response.json();
}).then(function(data) {
  console.log(data);
}).catch(function(err) {
  console.log('Fetch Error :-S', err);
});


document.body.appendChild(x)
