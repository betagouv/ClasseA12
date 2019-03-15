describe("First test", function () {
    it("Does not do much", function () {
        cy.visit("http://localhost:1234")

        // The default value for the keyword selector is empty (all videos but
        // the ones related to the project itself
        cy.get("#keywords").should("have.value", "")
            // Selecting the option for the project videos
            .select("Les vidéos à propos du projet Classe à 12")
            .should("have.value", "Le projet Classe à 12")


        // Only videos with the "Le project Classe à 12" keyword are listed
        cy.get(".card").find(".video-keywords")
            .each(keywords => {
                expect(keywords).to.contain("Le projet Classe à 12")
            })
    });
});