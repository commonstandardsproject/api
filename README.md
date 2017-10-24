[![Common Standards Project Homepage](https://cl.ly/3U43401V0P2o/download/Screen%20Shot%202016-08-19%20at%205.02.51%20PM.png)](http://commonstandardsproject.com)

## What is this?
API for the Common Standards Project, a database of academic standards from all 50 states, organizations, districts, and school. Check out a live API at [http://api.commonstandardsproject.com/](http://api.commonstandardsproject.com/), read the documentation at [http://commonstandardsproject.com](http://commonstandardsproject.com), or check out the [standards importer](https://github.com/commonstandardsproject/standards-importer) to import the standards from the API into your database. Only need the data for one set of standards and don't want to mess with an importer? Go to the [api](http://api.commonstandardsproject.com) where you can get the JSON for a standard set by typing in the standard set id.

## Why?

State and national standards connect to nearly every part K-12 education. In order for modern K12 edtech companies to use these standards in their apps, they need JSON formatted, well organized data.

Also, for K12 edtech companies to interoperate, they need a common language and identifier for standards. Without GUIDs for each standard, vendors have a hard time speaking making their align with each other. For instance, without a common standard GUID, a gradebook assignment can't be easily matched up with lesson plan from a different vendor.

## There's a hosted version that already has all the standards imported, right? 

You bet! Head over to [http://commonstandardsproject.com](http://commonstandardsproject.com). You'll be able to sign up for an API key and get access to instant standards search provided by Algolia.


## Hasn't this been done already?

Sort of.

* The [Achievement Standards Network](http://asn.jesandco.org/) has created XML and JSON versions of the standards. In our experience, their schema doesn't fully address our needs.
* [Academic Benchmarks](academicbenchmarks.com) is a company that sells XML and JSON versions of the standars. Like with ASN,
we weren't satisfied with their schema.
* [OpenSALT/CASE](https://sites.google.com/view/opensalt/home) is an open format for standards. It came out after CSP was created. We like their format for individual standards, but the semantics don't reflect the organization we see in the real world. See more below.


## What is this?

A few things. First, it's the web api. To see the standards and sign up for an API key, visit [http://commonstandardsproject.com](http://commonstandardsproject.com). Second, it's an importer script that downloads the Creative Commons licensed standards from ASN and munges it around until it's in a format that's more conducive for modern edtech companies. Third, it's a search interface (at commonstandardsproject.com) for students, parents, and educators to use to search and compare standards.


## Who is behind this?

[Common Curriculum](https://commoncurriculum.com). I'm Scott and I was a teacher for 4 years in Baltimore City Public Schools and then left to start Common Curriculum. I've wasted too many hours of my life munging standards data and I want to save other edtech companies from having to do the same. Also, I really want to be able to see the barriers to edtech integrations come down. Standards are one of the more unifying elements in edtech, yet we lack a common set of GUIDs or shared database of standards. I want to fix that.

Since publishing the standards online, other contributors have come aboard and are working to improve and extend the project. Standards affect nearly all edtech companies, so if you have an idea (or a need), get a hold of me scott (at) commoncurriculum (dot) com. I'd love to hear your ideas and see if we can make something work!


## Guiding Principles of the data format

When we took on the task of importing the standards, a few principles guided our work:

* **Group standards for practioners and in the way they're intended to be grouped**: States publish standards into documents. Each document describes the standards for a course (e.g. First grade math or HS English). For teachers to navigate standards, they need to be grouped in similar ways. 

* **Respect the original formatting**: Standards have hierarchy, codes, and bullet points galore. The hierarchical presentation of a set of standards should be easy for a developer to produce.

* **GUID**: Each standard should have a guid that edtech companies can use for integrations.

* **Easy to fix**: Converting 50 state standards is a monumental task (and one we're grateful ASN takes on). There will be typos and we want users to find them and fix them. Thus, each set of standards is versioned and changes can be submitted for approval.

* **Easy to add to**: Schools & districts create their own standards (outside of their state). They should be able to publish those standards and share them with their vendors.

## I don't want to use the API -- I want to put the standards in my database

Great idea. You'll still need to use the API, but only once to pull the standards. Fortunately, this work has already been done for you! Go download the [standards importer project](https://github.com/commonstandardsproject/standards-importer) and run it. You'll have the standards sitting in your RDBMS in no time flat.

## How is this different from OpenSALT/CASE?

OpenSALT/CASE is great and we're excited they exist. They offer a way to align standards to each other -- we'd love to incorporate that work into CSP. Pull requests welcome!

- **Schema & Semantics** 
On a more trivial level, they provide a slightly different set of field names for standards. More substantially, they don't have a concept of a standard set. For the CASE format, standards are infinitely nested within a standard document. For those not familiar with a standards document, these are documents published by a state that have a ton of standards for a subject level (e.g. "Math"). Inside this massive PDF, the standards are grouped by grades (e.g. "Grade 1") or course (e.g. "Calculus"). Because a document contains so many standards across so many grades, the document isn't a useful as an organization device. Instead of grouping at the document level, standards need to be grouepd as they are grouped inside the document: by grade/course. You'll see this same grouping reflected in classrooms & districts: teachers & admins talk of standards in 3 dimensions: the jurisdiction ("I'm a teacher in Maryland"), the subject ("I'm teaching Math"), and the course or grade ("I'm teaching 1st grade"). Given the groupings inside the document created by the state and the mental model teachers & admins have, CSP groups standards into "standard sets". A Standard Set has three dimensions: jurisdiction, subject, and grade/course. They also have a document field which lets you find the document they came from, but the document isn't the fundamental grouping.

- **Pull Request feature**
In CSP, people can submit changes or additions and admins can approve, reject, or request feedback.

- **Useful ASN import**
While OpenSALT does import from ASN, it's doens't clean up the confusing grouping ASN delivers. To see more about ASN imports, see below.


## What does the Common Standards Project do to improve on ASN standards?

- **Normalize the attributes** This is also something OpenSALT does. ASN standards are rough to parse and a non-trivial amount of work goes into turning their format into a more normal looking JSON format.
- **Group the standards the way they were inteded to be grouped** ASN doesn't group standards into grades or subjects. We have to do a tremendous amount of work to deduplicate/duplicate standards and group them into grades/subjects. Compare the Texas standards imported from ASN on OpenSALT (https://salt-demo.edplancms.com/cftree/item/37290) and the ones we've imported (http://commonstandardsproject.com/search?ids=%5B%2228903EF2A9F9469C9BF592D4D0BE10F8_D100036C_grade-01%22%5D) We've grouped ours into grade levels (click "Grade 1" to see the other grades)
- **Create subjects** We normally figure out the subject from the document title which means someone has to go through the document titles by hand and convert them. We take something like, "Sunshine State's Standards for Excellence and Performance for All Students and Learners and Leaders for the 21st Century for English and Language Arts" and turn it into "English & Language Arts". This requires a significant amount of manual effort. Here's the list: https://github.com/commonstandardsproject/api/blob/master/importer/matchers/source_to_subject_mapping_grouped.rb

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
