module DB 

using SQLite


export Note, opendb, closedb, createtables, addnote, updatenote, deletenote, getnote, getnotes

struct Note 
    id::Int64
    datetime::AbstractString 
    subject::AbstractString
    content::AbstractString
end 

function opendb(dbpath::String)::SQLite.DB
    return SQLite.DB(dbpath)
end 

function closedb(db::SQLite.DB)
    SQLite.close(db)
end 

function createtables(db::SQLite.DB)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS Notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            datetime TEXT NOT NULL,
            subject TEXT NOT NULL,
            content TEXT NOT NULL
        )
    """)
end 

function addnote(db::SQLite.DB, datetime::AbstractString, subject::AbstractString, content::AbstractString)::Int64
    SQLite.execute(db, "INSERT INTO Notes (datetime, subject, content) VALUES (?, ?, ?)", [datetime, subject, content])
    return SQLite.last_insert_rowid(db)
end 

function updatenote(db::SQLite.DB, id::Int64, datetime::AbstractString, subject::AbstractString, content::AbstractString)
    SQLite.execute(db, "UPDATE Notes SET datetime = ?, subject = ?, content = ? WHERE id = ?", [datetime, subject, content, id])
end 

function deletenote(db::SQLite.DB, id::Int64)
    SQLite.execute(db, "DELETE FROM Notes WHERE id = ?", [id])
end 

function getnote(db::SQLite.DB, id::Int64)::Union{Note, Nothing}
    result = DBInterface.execute(db, "SELECT id, datetime, subject, content FROM Notes WHERE id = $id")
    for row in result
        # single result, early termination
        return Note(row[1], row[2], row[3], row[4])
    end
    return nothing
end 

function getnotes(db::SQLite.DB)::Vector{Note}
    sql = """
    SELECT id, datetime, subject, content 
    FROM Notes 
    ORDER BY datetime DESC
    LIMIT 10
    """
    result = DBInterface.execute(db, sql)
    notes = Note[]
    for row in result
        push!(notes, Note(row[1], row[2], row[3], row[4]))
    end 
    return notes
end 

function searchkeyword(db::SQLite.DB, keyword::AbstractString)::Vector{Note}
    sql = """
    SELECT id, datetime, subject, content 
    FROM Notes 
    WHERE datetime LIKE ? OR subject LIKE ? OR content LIKE ?
    ORDER BY datetime DESC
    """
    result = DBInterface.execute(db, sql, ["%$keyword%", "%$keyword%", "%$keyword%"])
    notes = Note[]
    for row in result
        push!(notes, Note(row[1], row[2], row[3], row[4]))
    end 
    return notes
end 


end 