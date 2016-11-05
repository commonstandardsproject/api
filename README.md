![Common Standards Project Homepage](https://cl.ly/3U43401V0P2o/download/Screen%20Shot%202016-08-19%20at%205.02.51%20PM.png)

## What is this?
API for the Common Standards Project, a database of academic standards from all 50 states, organizations, districts, and school. Check out a live API at [http://api.commonstandardsproject.com/](http://api.commonstandardsproject.com/), read the documentation at [http://commonstandardsproject.com](http://commonstandardsproject.com), or check out the [standards importer](https://github.com/commonstandardsproject/standards-importer) to import the standards from the API into your database. Only need the data for one set of standards and don't want to mess with an importer? Go to the [api](http://api.commonstandardsproject.com) where you can get the JSON for a standard set by typing in the standard set id.

## Why?

State and national standards connect to nearly every part K-12 education. In order for modern K12 edtech companies to use these standards in their apps, they need JSON formatted, well organized data.

Also, for K12 edtech companies to interoperate, they need a common language and identifier for standards. Without GUIDs for each standard, vendors have a hard time speaking making their align with each other. For instance, without a common standard GUID, a gradebook assignment can't be easily matched up with lesson plan from a different vendor.


## Hasn't this been done already?

Sort of.

* The [Achievement Standards Network](http://asn.jesandco.org/) has created XML and JSON versions of the standards. In our experience, their schema doesn't fully address our needs.
* [Academic Benchmarks](academicbenchmarks.com) is a company that sells XML and JSON versions of the standars. Like with ASN,
we weren't satisfied with their schema.


## What is this?

A few things. First, it's the web api. To see the standards and sign up for an API key, visit [http://commonstandardsproject.com](http://commonstandardsproject.com). Second, it's an importer script that downloads the Creative Commons licensed standards from ASN and munges it around until it's in a format that's more conducive for modern edtech companies. Third, it's a search interface (at commonstandardsproject.com) for students, parents, and educators to use to search and compare standards.


## Who is behind this?

I'm Scott and I was a teacher for 4 years in Baltimore City Public Schools and then left to start Common Curriculum. I've wasted too many hours of my life munging standards data and I want to save other edtech companies from having to do the same. Also, I really want to be able to see the barriers to edtech integrations come down. Standards are one of the more unifying elements in edtech, yet we lack a common set of GUIDs or shared database of standards. I want to fix that.

Since publishing the standards online, other contributors have come aboard and are working to improve and extend the project. Standards affect nearly all edtech companies, so if you have an idea (or a need), get a hold of me scott (at) commoncurriculum (dot) com. I'd love to hear your ideas and see if we can make something work!


## Guiding Principles of the data format

When we took on the task of importing the standards, a few principles guided our work:

* **Respect the original organization**: States publish standards into documents. Each document describes the standards for a course (e.g. First grade math or HS English). For teachers to navigate standards, they need to be grouped in similar ways.

* **Respect the original formatting**: Standards have hierarchy, codes, and bullet points galore. The hierarchical presentation of a set of standards should be easy for a developer to produce.

* **GUID**: Each standard should have a guid.

* **Easy to fix**: Converting 50 state standards is a monumental task (and one we're grateful ASN takes on). There will be typos and we want users to find them and fix them. Thus, each set of standards is versioned and changes can be submitted for approval.

* **Easy to add to**: Schools & districts create their own standards (outside of their state). They should be able to publish those standards and share them with their vendors.

## I don't want to use the API -- I want to put the standards in my database

Great idea. You'll still need to use the API, but only once to pull the standards. Fortunately, this work has already been done for you! Go download the [standards importer project](https://github.com/commonstandardsproject/standards-importer) and run it. You'll have the standards sitting in your RDBMS in no time flat.

## Development

There are a few tasks that must be completed to get running with a local copy of the project for development purposes:


**Getting Setup**
* Install [MongoDB](https://www.mongodb.org/) or `brew install mongodb`
* Clone the repo and run `bundle install` to get all the gems you will need
* Install [Forego](https://github.com/ddollar/forego) or [Foreman](https://github.com/ddollar/foreman): `brew install forego`
* Run `forego run importer/cli setup` to create a default user and a sample .env file

**Importing the standards**
* Run `forego run importer/cli import` to import the standards

**Viewing the API docs/using the API**
* Run `forego start dev` to start the application on your local machine. Foreman will automatically use the variables in your `.env` file.
* Point your browser at `http://localhost:9393` and bask in the goodness of beautifully formatted standards

## Contributing!

Join the mailing list and we'll help you out: [https://groups.google.com/d/forum/common-standards-project](https://groups.google.com/d/forum/common-standards-project)
