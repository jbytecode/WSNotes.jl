const ws = new WebSocket("ws://localhost:8000/ws");

ws.onopen = function (event) {
    console.log("WebSocket connection established. Sending ping message...");
    sendPing();
};

ws.onmessage = function (event) {
    const message = JSON.parse(event.data);
    console.log("Received message:", message);
    let type = message.type;
    if (type === "pong") {
        console.log("Received pong message.");
        // Now its time to get all notes from the server
        getNotes();
    } else if (type === "error") {
        alert("Error from server: " + message.message);
    } else if (type === "addnote_response") {
        console.log("New record save with id :", message.id);
    } else if (type === "updatenote_response") {
        console.log("Record updated with id :", message.id);
        getNotes(); // Refresh the notes table after update
    } else if (type === "deletenote_response") {
        console.log("Record deleted with id :", message.id);
        getNotes(); // Refresh the notes table after deletion
    } else if (type === "getnote_response") {
        let id = message.note.id;
        let datetime = message.note.datetime;
        let subject = message.note.subject;
        let content = message.note.content;
        console.log("Record retrieved:", { id, datetime, subject, content });
    } else if (type === "getnotes_response") {
        let notes = message.notes;
        console.log("All records retrieved:", notes);
        console.log("Total records:", notes.length);
        decorateNotesTable(notes); // Call the function to decorate the notes table with the retrieved notes
    } else if (type === "searchnotes_response") {
        let notes = message.notes;
        console.log("Search results retrieved:", notes);
        console.log("Total search results:", notes.length);
        decorateNotesTable(notes); // Call the function to decorate the notes table with the search results
    } else {
        console.log("Unknown received message of type:", type);
    }
};

ws.onclose = function (event) {
    console.log("WebSocket connection closed. Event: ", event);
    console.log("Error: ", event.reason);
};

ws.onerror = function (error) {
    console.error("WebSocket error:", error);
};


const sendPing = () => {
    const pingMessage = JSON.stringify({ type: "ping" });
    ws.send(pingMessage);
    console.log("Sent ping message.");
};

const addNote = (datetime, subject, content) => {
    const addNoteMessage = JSON.stringify({
        type: "addnote",
        datetime: datetime,
        subject: subject,
        content: content
    });
    ws.send(addNoteMessage);
    console.log("Sent addnote message:", addNoteMessage);
};

const updateNote = (id, datetime, subject, content) => {
    const updateNoteMessage = JSON.stringify({
        type: "updatenote",
        id: id,
        datetime: datetime,
        subject: subject,
        content: content
    });
    ws.send(updateNoteMessage);
    console.log("Sent updatenote message:", updateNoteMessage);
};

const deleteNote = (id) => {
    const deleteNoteMessage = JSON.stringify({
        type: "deletenote",
        id: id
    });
    ws.send(deleteNoteMessage);
    console.log("Sent deletenote message:", deleteNoteMessage);
};

const getNote = (id) => {
    const getNoteMessage = JSON.stringify({
        type: "getnote",
        id: id
    });
    ws.send(getNoteMessage);
    console.log("Sent getnote message:", getNoteMessage);
};

const getNotes = () => {
    const getNotesMessage = JSON.stringify({
        type: "getnotes"
    });
    ws.send(getNotesMessage);
    console.log("Sent getnotes message:", getNotesMessage);
};

const shutdownServer = () => {
    const shutdownMessage = JSON.stringify({
        type: "shutdown"
    });
    ws.send(shutdownMessage);
    console.log("Sent shutdown message:", shutdownMessage);
};


const searchNotes = (keyword) => {
    const searchNotesMessage = JSON.stringify({
        type: "searchnotes",
        keyword: keyword
    });
    ws.send(searchNotesMessage);
    console.log("Sent searchnotes message:", searchNotesMessage);
};

// YY-MM-DD HH:MM:SS format
const getCurrentDateTime = () => {
    const now = new Date();
    const year = now.getFullYear().toString().slice(-2);
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
};




// Entry point 
const decorateNotesTable = (notes) => {
    const tableBody = document.getElementById("notes-table-body");
    tableBody.innerHTML = ""; // Clear existing rows

    notes.forEach(note => {
        const row = document.createElement("tr");

        // id cell is encapculated by a link <a>, when clicked 
        // it calls showNoteDetails(note.id) to show the note details in a modal or a separate section.
        const idCell = document.createElement("td");
        const idLink = document.createElement("a");
        idLink.href = "#";
        idLink.textContent = note.id;
        idLink.onclick = () => showNoteDetails(note);
        idCell.appendChild(idLink);
        row.appendChild(idCell);

        const datetimeCell = document.createElement("td");
        datetimeCell.textContent = note.datetime;
        row.appendChild(datetimeCell);

        const subjectCell = document.createElement("td");
        subjectCell.textContent = note.subject;
        row.appendChild(subjectCell);

        const contentCell = document.createElement("td");
        contentCell.textContent = note.content;
        row.appendChild(contentCell);

        tableBody.appendChild(row);
    });
}


const showNoteDetails = (note) => {
    const noteDialog = document.getElementById("note-dialog");
    const noteForm = document.getElementById("note-form");
    const noteIdInput = document.getElementById("note-id");
    const noteDatetimeInput = document.getElementById("note-datetime");
    const noteSubjectInput = document.getElementById("note-subject");
    const noteContentInput = document.getElementById("note-content");

    // Populate the form with the note details
    noteIdInput.value = note.id;
    noteDatetimeInput.value = note.datetime; // Set the datetime value
    noteSubjectInput.value = note.subject; // Set the subject value
    noteContentInput.value = note.content; // Set the content value

    // Show the dialog
    noteDialog.showModal();
};


const hideNoteDetails = () => {
    const noteDialog = document.getElementById("note-dialog");
    noteDialog.close();
};


const DialogUpdate = () => {
    const noteIdInput = document.getElementById("note-id").value;
    const noteDatetimeInput = document.getElementById("note-datetime").value;
    const noteSubjectInput = document.getElementById("note-subject").value;
    const noteContentInput = document.getElementById("note-content").value;
    console.log("Updating note with id:", noteIdInput, "datetime:", noteDatetimeInput, "subject:", noteSubjectInput, "content:", noteContentInput);
    updateNote(noteIdInput, noteDatetimeInput, noteSubjectInput, noteContentInput);
    hideNoteDetails();
};

const DialogDelete = () => {
    const noteIdInput = document.getElementById("note-id").value;
    console.log("Deleting note with id:", noteIdInput);
    // Ask user if they are sure they want to delete the note
    if (!confirm("Are you sure you want to delete this note?")) {
        return; // Exit if user cancels
    }
    deleteNote(noteIdInput);
    hideNoteDetails();
};