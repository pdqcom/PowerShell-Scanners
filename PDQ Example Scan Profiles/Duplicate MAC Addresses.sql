SELECT
	  Computers.Name AS "Computer Name"
	, MACDuplicates.MacAddress AS "MAC Address"
FROM
	-- https://stackoverflow.com/a/21980136
	(
		SELECT
			Computers.MacAddress
			, COUNT(*) AS "Count"
		FROM
			Computers
		WHERE
			<ComputerFilter>
			AND
			-- I don't know why "IS NOT NULL" didn't work here.
			Computers.MacAddress <> ''
		GROUP BY
			Computers.MacAddress
		HAVING
			Count > 1
	) MACDuplicates
INNER JOIN
	Computers USING (MacAddress)
WHERE
	<ComputerFilter>
ORDER BY
	"Computer Name"