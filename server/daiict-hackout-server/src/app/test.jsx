async function name(formdata) {
    const response = await fetch('/api/report', {
        method: "POST",
        headers: "",
        formdata: formdata,
    });
}

