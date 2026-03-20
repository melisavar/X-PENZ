//Get todays date
window.addEventListener('DOMContentLoaded', () => {
    const pad = (n) => n.toString().padStart(2, '0');
    const now = new Date();
    const todayStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
    document.getElementById('date').value = todayStr;
});

//Switching tabs
document.querySelectorAll(".tab-button").forEach(btn => {
    btn.addEventListener("click", () => {
        document.querySelectorAll(".tab-button").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");

        const tab = btn.dataset.tab;
        document.querySelectorAll(".tab-panel").forEach(panel => {
            panel.classList.toggle("active", panel.id === tab);
        });
    });
});

// Manual Form Submission
document.getElementById('manual-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const frontendDate = document.getElementById('date').value;
    let formattedDate;
    
    if (frontendDate) {
        const [year, month, day] = frontendDate.split('-');
        const pad = (n) => n.toString().padStart(2, '0');
        formattedDate = `${year}-${pad(month)}-${pad(day)}`;
    } else {
        const today = new Date();
        const pad = (n) => n.toString().padStart(2, '0');
        formattedDate = `${today.getFullYear()}-${pad(today.getMonth() + 1)}-${pad(today.getDate())}`;
    }
    
    const expense = {
        amount: parseFloat(document.getElementById('amount').value),
        vendor: document.getElementById('vendor').value.trim(),
        category: document.getElementById('category').value.trim(),
        date: formattedDate
    };

    try {
        const response = await fetch("https://w18bf3d4th.execute-api.us-east-1.amazonaws.com/prod/manual-extract", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(expense)
        });
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || "Failed to add expense");
        }

        const responseData = await response.json();
        alert("Expense added successfully!");
        document.getElementById('manual-form').reset();

        const pad = (n) => n.toString().padStart(2, '0');
        const now = new Date();
        const todayStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
        document.getElementById('date').value = todayStr;
        
    } catch (error) {
        console.error("Manual add error:", error);
        alert(`Error adding expense: ${error.message}`);
    }
});

// Voice Recording
document.getElementById('voice-record').addEventListener('click', async () => {
    const statusEl = document.getElementById('voice-status');
    statusEl.innerHTML = '<div class="processing">Listening... Speak your expense now</div>';
    
    try {
        if (!('webkitSpeechRecognition' in window)) {
            statusEl.innerHTML = '<div class="error-message">Voice recognition not supported in your browser</div>';
            return;
        }

        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        const recognition = new SpeechRecognition();
        
        recognition.continuous = false;
        recognition.interimResults = false;
        recognition.lang = 'en-US';

        recognition.start();

        recognition.onresult = async (event) => {
            const voiceText = event.results[0][0].transcript;
            statusEl.innerHTML = `<div class="processing">Processing: "${voiceText}"</div>`;
            
            try {
                const response = await fetch("https://w18bf3d4th.execute-api.us-east-1.amazonaws.com/prod/voice-extract", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ voiceText })
                });
                
                const result = await response.json();
                
                if (!response.ok) {
                    throw new Error(result.error || result.message || "Failed to process voice input");
                }

                const expenseData = result.data || result;
                
                statusEl.innerHTML = `
                    <div class="success-message">
                        Expense added successfully!<br>
                    </div>
                `;
            } catch (error) {
                console.error("Error:", error);
                statusEl.innerHTML = `
                    <div class="error-message">
                        Error: ${error.message || "Failed to process voice input"}
                    </div>
                `;
            }
        };

        recognition.onerror = (event) => {
            let errorMessage = "Error occurred in voice recognition";
            switch(event.error) {
                case 'no-speech': errorMessage = "No speech detected"; break;
                case 'audio-capture': errorMessage = "Microphone not available"; break;
                case 'not-allowed': errorMessage = "Microphone access denied"; break;
                default: errorMessage = `Error: ${event.error}`;
            }
            statusEl.innerHTML = `<div class="error-message">${errorMessage}</div>`;
        };

    } catch (error) {
        console.error("Error:", error);
        statusEl.innerHTML = `
            <div class="error-message">
                Error setting up voice recognition: ${error.message}
            </div>
        `;
    }
});

// Image Upload
document.getElementById("upload-image").addEventListener("click", async () => {
    const fileInput = document.getElementById("image-input");
    const statusText = document.getElementById("image-status");

    if (!fileInput.files.length) {
        statusText.textContent = "Please select an image file first.";
        return;
    }

    const file = fileInput.files[0];
    const fileName = `${Date.now()}_${file.name}`;
    const fileType = file.type;

    try {
        //Get a pre-signed URL
        const res = await fetch(`https://w18bf3d4th.execute-api.us-east-1.amazonaws.com/prod/generate-URL?filename=${encodeURIComponent(fileName)}&filetype=${encodeURIComponent(fileType)}`);
        const data = await res.json();
        console.log("Lambda response:", data);

        if (!data.uploadURL) throw new Error("Failed to get upload URL");

        //Upload the image file to S3
        const uploadRes = await fetch(data.uploadURL, {
            method: "PUT",
            headers: { "Content-Type": fileType },
            body: file
        });

        if (!uploadRes.ok) throw new Error(`S3 upload failed with status ${uploadRes.status}`);

        statusText.textContent = "Image uploaded successfully!!";
        fileInput.value = "";

    } catch (err) {
        console.error("Upload error:", err);
        statusText.textContent = `Upload failed: ${err.message}`;
    }
});
